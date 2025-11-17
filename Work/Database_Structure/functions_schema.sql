-- Exported: 2025-11-13 21:21:26
-- Database: russianorbatukraine

--
-- PostgreSQL database dump
--

\restrict rW6Tct2gLJ5qsNsfhC2vTfSusr3UjxBHCRUfpv7ywE7HyJEhTlZ3Q7ZpTLejmMt

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: functions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA functions;


--
-- Name: add_unit_position(character varying, timestamp without time zone, double precision, double precision, character varying, character varying, text, text, text, text, character varying, character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.add_unit_position(p_unit_key character varying, p_observation_date timestamp without time zone, p_latitude double precision, p_longitude double precision, p_confidence_level character varying DEFAULT 'Medium'::character varying, p_source_type character varying DEFAULT NULL::character varying, p_geo_source text DEFAULT NULL::text, p_ua_source text DEFAULT NULL::text, p_ru_source text DEFAULT NULL::text, p_notes text DEFAULT NULL::text, p_action character varying DEFAULT NULL::character varying, p_analyst character varying DEFAULT NULL::character varying) RETURNS TABLE(observation_id integer, unit_key character varying, unit_name character varying, observation_date timestamp without time zone, status text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_obs_id INTEGER;
    unit_name_var VARCHAR(100);
BEGIN
    -- Verify unit exists
    SELECT unit_name INTO unit_name_var 
    FROM russian_units 
    WHERE russian_units.unit_key = p_unit_key;
    
    IF unit_name_var IS NULL THEN
        RAISE EXCEPTION 'Unit key % not found in russian_units', p_unit_key;
    END IF;
    
    -- Insert new position
    INSERT INTO unit_positions (
        unit_key, observation_date, location, confidence_level,
        source_type, geo_source, ua_source, ru_source, 
        notes, action, analyst, created_date
    ) VALUES (
        p_unit_key, p_observation_date, 
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326),
        p_confidence_level, p_source_type, p_geo_source, 
        p_ua_source, p_ru_source, p_notes, p_action, p_analyst,
        p_observation_date  -- Set created_date = observation_date
    ) RETURNING unit_positions.observation_id INTO new_obs_id;
    
    -- Update russian_units coordinates
    PERFORM update_unit_coordinates();
    
    RETURN QUERY 
    SELECT new_obs_id, p_unit_key, unit_name_var, 
           p_observation_date, 'New position added'::TEXT;
END;
$$;


--
-- Name: assign_operational_area(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.assign_operational_area() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    settlement_geom GEOMETRY;
    op_area_id INTEGER;
BEGIN
    -- Skip if already assigned
    IF NEW.operational_area_id IS NOT NULL THEN
        RETURN NEW;
    END IF;
    
    -- Try to get area from PCODE
    IF NEW.adm4_pcode IS NOT NULL THEN
        SELECT ST_Centroid(geom) INTO settlement_geom
        FROM spatial_ref.ukrainesettlements
        WHERE adm4_pcode = NEW.adm4_pcode
        LIMIT 1;
        
        IF settlement_geom IS NOT NULL THEN
            SELECT oa.area_id INTO op_area_id
            FROM spatial_ref.operational_areas oa
            WHERE ST_Within(settlement_geom, oa.geom)
            LIMIT 1;
        END IF;
    END IF;
    
    -- If no PCODE or not found, try location
    IF op_area_id IS NULL AND NEW.location IS NOT NULL THEN
        SELECT oa.area_id INTO op_area_id
        FROM spatial_ref.operational_areas oa
        WHERE ST_Within(NEW.location, oa.geom)
        LIMIT 1;
    END IF;
    
    -- Assign the area
    NEW.operational_area_id := op_area_id;
    
    RETURN NEW;
END;
$$;


--
-- Name: FUNCTION assign_operational_area(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.assign_operational_area() IS 'Automatically assigns operational area based on PCODE or location. Runs BEFORE INSERT.';


--
-- Name: assign_unknown_unit_key(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.assign_unknown_unit_key() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NEW.unknown_unit_key IS NULL THEN
        NEW.unknown_unit_key := generate_unknown_unit_key(NEW.unknown_category);
    END IF;
    
    IF NEW.unknown_unit_key !~ '^z[ab]\d{5}$' THEN
        RAISE EXCEPTION 'Invalid unknown_unit_key format: %. Must be z[a|b]##### (e.g., za00001, zb00042)', 
            NEW.unknown_unit_key;
    END IF;
    
    IF SUBSTRING(NEW.unknown_unit_key FROM 2 FOR 1) != NEW.unknown_category THEN
        RAISE EXCEPTION 'Key category (%) does not match unknown_category (%)', 
            SUBSTRING(NEW.unknown_unit_key FROM 2 FOR 1), NEW.unknown_category;
    END IF;
    
    RETURN NEW;
END;
$_$;


--
-- Name: backfill_maid_registry_stats(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.backfill_maid_registry_stats(target_maid_id character varying DEFAULT NULL::character varying) RETURNS TABLE(maid_id character varying, first_observed timestamp without time zone, last_observed timestamp without time zone, total_observations bigint, action character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- If specific MAID provided, update just that one
    IF target_maid_id IS NOT NULL THEN
        RETURN QUERY
        WITH stats AS (
            SELECT 
                mp.maid_id,
                MIN(mp.timestamp) as first_obs,
                MAX(mp.timestamp) as last_obs,
                COUNT(*) as total_obs
            FROM maid_positions mp
            WHERE mp.maid_id = target_maid_id
            GROUP BY mp.maid_id
        )
        UPDATE maid_registry mr
        SET 
            first_observed = stats.first_obs,
            last_observed = stats.last_obs,
            total_observations = stats.total_obs,
            updated_date = CURRENT_TIMESTAMP
        FROM stats
        WHERE mr.maid_id = stats.maid_id
        RETURNING 
            mr.maid_id,
            mr.first_observed,
            mr.last_observed,
            mr.total_observations,
            'UPDATED'::VARCHAR(20) as action;
    
    -- Otherwise, update all MAIDs in registry
    ELSE
        RETURN QUERY
        WITH stats AS (
            SELECT 
                mp.maid_id,
                MIN(mp.timestamp) as first_obs,
                MAX(mp.timestamp) as last_obs,
                COUNT(*) as total_obs
            FROM maid_positions mp
            INNER JOIN maid_registry mr ON mp.maid_id = mr.maid_id
            GROUP BY mp.maid_id
        )
        UPDATE maid_registry mr
        SET 
            first_observed = stats.first_obs,
            last_observed = stats.last_obs,
            total_observations = stats.total_obs,
            updated_date = CURRENT_TIMESTAMP
        FROM stats
        WHERE mr.maid_id = stats.maid_id
        RETURNING 
            mr.maid_id,
            mr.first_observed,
            mr.last_observed,
            mr.total_observations,
            'UPDATED'::VARCHAR(20) as action;
    END IF;
END;
$$;


--
-- Name: FUNCTION backfill_maid_registry_stats(target_maid_id character varying); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.backfill_maid_registry_stats(target_maid_id character varying) IS 'Backfills first_observed, last_observed, and total_observations for MAIDs in registry. 
Pass a specific maid_id to update one MAID, or NULL to update all MAIDs in registry.';


--
-- Name: batch_register_maids(jsonb); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.batch_register_maids(maids_data jsonb) RETURNS TABLE(maid_id character varying, maid_alias character varying, status character varying, error_message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    maid_record JSONB;
BEGIN
    FOR maid_record IN SELECT * FROM jsonb_array_elements(maids_data)
    LOOP
        BEGIN
            -- Attempt to register
            PERFORM register_from_queue(
                maid_record->>'maid_id',
                maid_record->>'alias',
                COALESCE(maid_record->>'priority', 'MEDIUM'),
                maid_record->>'notes'
            );
            
            -- Success
            RETURN QUERY SELECT 
                (maid_record->>'maid_id')::VARCHAR(36),
                (maid_record->>'alias')::VARCHAR(100),
                'SUCCESS'::VARCHAR(20),
                NULL::TEXT;
                
        EXCEPTION WHEN OTHERS THEN
            -- Failure - capture error
            RETURN QUERY SELECT 
                (maid_record->>'maid_id')::VARCHAR(36),
                (maid_record->>'alias')::VARCHAR(100),
                'FAILED'::VARCHAR(20),
                SQLERRM::TEXT;
        END;
    END LOOP;
END;
$$;


--
-- Name: FUNCTION batch_register_maids(maids_data jsonb); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.batch_register_maids(maids_data jsonb) IS 'Register multiple MAIDs at once from JSON input. 
Returns success/failure status for each MAID.';


--
-- Name: batch_update_unit_keys(jsonb, boolean); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.batch_update_unit_keys(updates jsonb, dry_run boolean DEFAULT true) RETURNS TABLE(old_key character varying, new_key character varying, status text, affected_positions bigint, affected_maids bigint, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    update_record JSONB;
    old_unit_key VARCHAR(10);
    new_unit_key VARCHAR(10);
    pos_count BIGINT;
    maid_count BIGINT;
    error_msg TEXT;
BEGIN
    FOR update_record IN SELECT * FROM jsonb_array_elements(updates)
    LOOP
        old_unit_key := update_record->>'old_key';
        new_unit_key := update_record->>'new_key';
        
        -- Validation
        IF old_unit_key IS NULL OR new_unit_key IS NULL THEN
            RETURN QUERY SELECT 
                old_unit_key, new_unit_key, 'SKIPPED'::TEXT, 
                0::BIGINT, 0::BIGINT,
                'Both old_key and new_key must be provided'::TEXT;
            CONTINUE;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM russian_units WHERE unit_key = old_unit_key) THEN
            RETURN QUERY SELECT 
                old_unit_key, new_unit_key, 'ERROR'::TEXT,
                0::BIGINT, 0::BIGINT,
                'Old key does not exist'::TEXT;
            CONTINUE;
        END IF;
        
        IF EXISTS (SELECT 1 FROM russian_units WHERE unit_key = new_unit_key) THEN
            RETURN QUERY SELECT 
                old_unit_key, new_unit_key, 'ERROR'::TEXT,
                0::BIGINT, 0::BIGINT,
                'New key already exists'::TEXT;
            CONTINUE;
        END IF;
        
        -- Count affected records
        SELECT COUNT(*) INTO pos_count FROM unit_positions WHERE unit_key = old_unit_key;
        SELECT COUNT(*) INTO maid_count FROM maid_orbat_associations WHERE associated_unit_key = old_unit_key;
        
        -- Perform update if not dry run
        IF NOT dry_run THEN
            BEGIN
                UPDATE russian_units SET unit_key = new_unit_key WHERE unit_key = old_unit_key;
                
                RETURN QUERY SELECT 
                    old_unit_key, new_unit_key, 'SUCCESS'::TEXT,
                    pos_count, maid_count,
                    'Updated successfully'::TEXT;
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
                RETURN QUERY SELECT 
                    old_unit_key, new_unit_key, 'FAILED'::TEXT,
                    pos_count, maid_count,
                    error_msg;
            END;
        ELSE
            RETURN QUERY SELECT 
                old_unit_key, new_unit_key, 'DRY_RUN'::TEXT,
                pos_count, maid_count,
                'Would update (dry run only)'::TEXT;
        END IF;
    END LOOP;
END;
$$;


--
-- Name: clean_unit_name(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.clean_unit_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Clean the unit_name
    NEW.unit_name = TRIM(REGEXP_REPLACE(NEW.unit_name, '\s+', ' ', 'g'));
    RETURN NEW;
END;
$$;


--
-- Name: cleanup_committed_mention_status(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.cleanup_committed_mention_status() RETURNS TABLE(updated_count integer, oldest_mention_date timestamp without time zone, newest_mention_date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_updated_count INTEGER;
    v_oldest TIMESTAMP;
    v_newest TIMESTAMP;
BEGIN
    -- Update review_status for committed mentions still marked as pending
    WITH updated AS (
        UPDATE unit_mentions
        SET review_status = 'approved'
        WHERE review_status = 'pending'
        AND committed_to_position_id IS NOT NULL
        RETURNING mention_id, observation_date
    )
    SELECT 
        COUNT(*)::INTEGER,
        MIN(observation_date),
        MAX(observation_date)
    INTO v_updated_count, v_oldest, v_newest
    FROM updated;
    
    -- Return summary of what was updated
    RETURN QUERY SELECT v_updated_count, v_oldest, v_newest;
    
    -- Log the cleanup action
    RAISE NOTICE 'Updated % mentions from pending to approved', v_updated_count;
    IF v_updated_count > 0 THEN
        RAISE NOTICE 'Date range: % to %', v_oldest, v_newest;
    END IF;
END;
$$;


--
-- Name: FUNCTION cleanup_committed_mention_status(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.cleanup_committed_mention_status() IS 'Weekly cleanup function to sync review_status with committed_to_position_id.
Sets review_status = ''approved'' for any mentions that have been committed but are still marked pending.

Usage:
  SELECT * FROM cleanup_committed_mention_status();
  
Returns: count of updated records and date range of affected mentions.
';


--
-- Name: create_initial_unit_position(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.create_initial_unit_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    initial_pcode VARCHAR(20);
    settlement_geom GEOMETRY;
BEGIN
    IF NEW.current_lat IS NOT NULL AND NEW.current_long IS NOT NULL THEN
        -- Changed: adm4_pcode in SELECT, but amd4_pcode in INSERT
        SELECT adm4_pcode INTO initial_pcode  -- Reading from ukrainesettlements
        FROM ukrainesettlements
        WHERE ST_Contains(
            geom, 
            ST_SetSRID(ST_MakePoint(NEW.current_long, NEW.current_lat), 4326)
        )
        LIMIT 1;
        
        INSERT INTO unit_positions (
            unit_key,
            observation_date,
            location,
            adm4_pcode,  -- Writing to unit_positions
            confidence_level,
            source_type,
            notes,
            analyst,
            created_date
        ) VALUES (
            NEW.unit_key,
            COALESCE(NEW.last_observed, CURRENT_TIMESTAMP),
            ST_SetSRID(ST_MakePoint(NEW.current_long, NEW.current_lat), 4326),
            initial_pcode,
            'Medium',
            'Initial Registration',
            format('Unit initially registered in ORBAT. MUN: %s%s', 
                   NEW.mun_number,
                   CASE WHEN initial_pcode IS NOT NULL 
                        THEN format(', PCODE: %s', initial_pcode) 
                        ELSE '' 
                   END),
            COALESCE(NEW.creator, 'System'),
            COALESCE(NEW.created_date, CURRENT_TIMESTAMP)
        );
    ELSIF NEW.basinglocation IS NOT NULL THEN
        SELECT adm4_pcode, ST_Centroid(geom)  -- Reading from ukrainesettlements
        INTO initial_pcode, settlement_geom
        FROM ukrainesettlements
        WHERE LOWER(adm4_en) LIKE LOWER('%' || NEW.basinglocation || '%')
        LIMIT 1;
        
        IF initial_pcode IS NOT NULL THEN
            INSERT INTO unit_positions (
                unit_key,
                observation_date,
                location,
                adm4_pcode,  -- Writing to unit_positions
                confidence_level,
                source_type,
                notes,
                analyst,
                created_date
            ) VALUES (
                NEW.unit_key,
                COALESCE(NEW.last_observed, CURRENT_TIMESTAMP),
                settlement_geom,
                initial_pcode,
                'Low',
                format('Unit registered with base location: %s, matched to PCODE: %s', 
                       NEW.basinglocation, initial_pcode),
                COALESCE(NEW.creator, 'System'),
                COALESCE(NEW.created_date, CURRENT_TIMESTAMP)
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: create_maid_alias(character varying, character varying, character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.create_maid_alias(target_maid_id character varying, alias_name character varying, priority character varying DEFAULT 'MEDIUM'::character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO maid_registry (maid_id, maid_alias, priority_level)
    VALUES (target_maid_id, alias_name, priority)
    ON CONFLICT (maid_id) DO UPDATE SET
        maid_alias = EXCLUDED.maid_alias,
        priority_level = EXCLUDED.priority_level,
        updated_date = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Alias % already exists for different MAID', alias_name;
        RETURN FALSE;
END;
$$;


--
-- Name: create_maid_unit_association(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.create_maid_unit_association(target_maid_id character varying, target_unit_key character varying, confidence_level character varying, analyst_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_association_id INTEGER;
    lookup_maid_alias VARCHAR(50);
BEGIN
    -- Look up the maid_alias from maid_registry
    SELECT maid_alias INTO lookup_maid_alias
    FROM maid_registry
    WHERE maid_id = target_maid_id;
    
    -- If MAID not found in registry, throw an error
    IF lookup_maid_alias IS NULL THEN
        RAISE EXCEPTION 'MAID ID % not found in maid_registry. Please register the MAID before creating associations.', target_maid_id;
    END IF;
    
    -- End any existing active associations for this MAID
    UPDATE maid_orbat_associations 
    SET association_date_end = CURRENT_TIMESTAMP
    WHERE maid_id = target_maid_id 
      AND association_date_end IS NULL;
    
    -- Create new association
    INSERT INTO maid_orbat_associations (
        maid_id, 
        maid_alias,
        associated_unit_key, 
        association_confidence,
        association_date_start, 
        analyst,
        validated,
        created_date
    ) VALUES (
        target_maid_id,
        lookup_maid_alias,
        target_unit_key, 
        confidence_level,
        CURRENT_TIMESTAMP,
        analyst_name,
        FALSE,
        CURRENT_TIMESTAMP
    ) RETURNING association_id INTO new_association_id;
    
    RETURN new_association_id;
END;
$$;


--
-- Name: create_maid_unit_facility_association(character varying, character varying, character varying, character varying, character varying, character varying, text); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.create_maid_unit_facility_association(target_maid_id character varying, target_unit_key character varying, confidence_level character varying, association_method character varying, target_facility_key character varying DEFAULT NULL::character varying, facility_type character varying DEFAULT 'DETECTED_AT'::character varying, evidence text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    association_id INTEGER;
    detection_count INTEGER := 0;
    first_detection TIMESTAMP;
    last_detection TIMESTAMP;
BEGIN
    -- If facility provided, get detection statistics
    IF target_facility_key IS NOT NULL THEN
        SELECT 
            COUNT(*),
            MIN(timestamp),
            MAX(timestamp)
        INTO detection_count, first_detection, last_detection
        FROM maid_positions mp
        JOIN russian_facilities rf ON rf.facility_key = target_facility_key
        WHERE mp.maid_id = target_maid_id
          AND ST_DWithin(mp.location::geography, rf.location::geography, 5000)
          AND mp.location_quality IN ('HIGH', 'MEDIUM');
    END IF;
    
    -- End any existing active associations
    UPDATE maid_orbat_associations 
    SET association_date_end = CURRENT_TIMESTAMP
    WHERE maid_id = target_maid_id 
      AND association_date_end IS NULL;
    
    -- Create new association with facility context
    INSERT INTO maid_orbat_associations (
        maid_id, associated_unit_key, association_confidence,
        association_method, association_date_start, supporting_evidence,
        facility_key, facility_association_type, facility_detection_count,
        facility_first_detection, facility_last_detection,
        analyst
    ) VALUES (
        target_maid_id, target_unit_key, confidence_level,
        association_method, CURRENT_TIMESTAMP, evidence,
        target_facility_key, facility_type, detection_count,
        first_detection, last_detection,
        CURRENT_USER
    ) RETURNING association_id INTO association_id;
    
    RETURN association_id;
END;
$$;


--
-- Name: detect_redeployments(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.detect_redeployments() RETURNS TABLE(returned_unit_key character varying, returned_unit_name character varying, from_area character varying, to_area character varying, is_first_deployment boolean, redeployments_logged integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    unit_rec RECORD;
    prev_area_id INTEGER;
    prev_obs_id INTEGER;
    prev_obs_date TIMESTAMP;
    curr_area_id INTEGER;
    curr_obs_id INTEGER;
    curr_obs_date TIMESTAMP;
    days_diff INTEGER;
    is_first BOOLEAN;
    from_area_name VARCHAR(254);
    to_area_name VARCHAR(254);
    redep_count INTEGER := 0;
BEGIN
    -- Loop through each Brigade/Regiment/Division
    FOR unit_rec IN 
        SELECT DISTINCT ru.unit_key, ru.unit_name
        FROM russian_units ru
        WHERE ru.echelon IN (17, 18, 21)  -- Only Brigade/Regiment/Division
    LOOP
        -- Get previous operational area
        SELECT 
            up.operational_area_id,
            up.observation_id,
            up.observation_date
        INTO prev_area_id, prev_obs_id, prev_obs_date
        FROM unit_positions up
        WHERE up.unit_key = unit_rec.unit_key
          AND up.operational_area_id IS NOT NULL
        ORDER BY up.observation_date DESC
        OFFSET 1 LIMIT 1;
        
        -- Get current operational area
        SELECT 
            up.operational_area_id,
            up.observation_id,
            up.observation_date
        INTO curr_area_id, curr_obs_id, curr_obs_date
        FROM unit_positions up
        WHERE up.unit_key = unit_rec.unit_key
          AND up.operational_area_id IS NOT NULL
        ORDER BY up.observation_date DESC
        LIMIT 1;
        
        -- Skip if no current area
        CONTINUE WHEN curr_area_id IS NULL;
        
        -- Determine if this is first deployment or redeployment
        is_first := (prev_area_id IS NULL);
        
        -- Check if area changed (or first deployment)
        IF prev_area_id IS NULL OR prev_area_id != curr_area_id THEN
            
            -- Get area names
            SELECT oa.name INTO from_area_name
            FROM spatial_ref.operational_areas oa
            WHERE oa.area_id = prev_area_id;
            
            SELECT oa.name INTO to_area_name
            FROM spatial_ref.operational_areas oa
            WHERE oa.area_id = curr_area_id;
            
            -- Calculate days between observations
            IF prev_obs_date IS NOT NULL THEN
                days_diff := EXTRACT(DAY FROM (curr_obs_date - prev_obs_date))::INTEGER;
            ELSE
                days_diff := NULL;
            END IF;
            
            -- Insert redeployment event
            INSERT INTO redeployment_events (
                unit_key,
                unit_name,
                from_area_id,
                to_area_id,
                from_observation_id,
                to_observation_id,
                redeployment_date,
                days_between,
                is_first_deployment,
                notes
            )
            VALUES (
                unit_rec.unit_key,
                unit_rec.unit_name,
                prev_area_id,
                curr_area_id,
                prev_obs_id,
                curr_obs_id,
                curr_obs_date,
                days_diff,
                is_first,
                CASE 
                    WHEN is_first THEN 'First deployment to ' || to_area_name
                    ELSE 'Redeployed from ' || COALESCE(from_area_name, 'Unknown') || ' to ' || to_area_name
                END
            )
            ON CONFLICT (unit_key, to_observation_id) DO NOTHING;
            
            redep_count := redep_count + 1;
            
            -- Return row
            RETURN QUERY SELECT 
                unit_rec.unit_key,
                unit_rec.unit_name,
                from_area_name,
                to_area_name,
                is_first,
                1;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Detected % redeployment events', redep_count;
END;
$$;


--
-- Name: FUNCTION detect_redeployments(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.detect_redeployments() IS 'Detects and logs redeployments for Brigade/Regiment/Division level units. Run manually after position updates.';


--
-- Name: detect_unit_movements(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.detect_unit_movements() RETURNS TABLE(movement_id integer, movement_category character varying, unit_key character varying, unit_name character varying, from_location character varying, to_location character varying, movement_date timestamp without time zone, days_between integer, movement_details text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- First detect operational redeployments (your existing logic, slightly modified)
    WITH unit_locations AS (
        SELECT 
            up.unit_key,
            ru.unit_name,
            up.observation_id,
            up.observation_date,
            up.operational_area_id,
            up.tactical_area_id,
            oa.name as operational_area_name,
            ta.tactical_area_name,
            ta.area_type as tactical_area_type,
            LAG(up.operational_area_id) OVER (
                PARTITION BY up.unit_key 
                ORDER BY up.observation_date
            ) as prev_operational_area_id,
            LAG(up.tactical_area_id) OVER (
                PARTITION BY up.unit_key 
                ORDER BY up.observation_date
            ) as prev_tactical_area_id,
            LAG(up.observation_id) OVER (
                PARTITION BY up.unit_key 
                ORDER BY up.observation_date
            ) as prev_observation_id,
            LAG(up.observation_date) OVER (
                PARTITION BY up.unit_key 
                ORDER BY up.observation_date
            ) as prev_observation_date,
            ROW_NUMBER() OVER (
                PARTITION BY up.unit_key 
                ORDER BY up.observation_date
            ) as position_sequence
        FROM unit_positions up
        JOIN russian_units ru ON up.unit_key = ru.unit_key
        LEFT JOIN spatial_ref.operational_areas oa ON up.operational_area_id = oa.area_id
        LEFT JOIN spatial_ref.tactical_areas ta ON up.tactical_area_id = ta.tactical_area_id
        WHERE ru.echelon IN (17, 18, 21)  -- Brigade, Regiment, Division only
          AND up.operational_area_id IS NOT NULL
    ),
    -- Detect operational redeployments
    operational_redeployments AS (
        SELECT 
            ul.unit_key,
            ul.unit_name,
            ul.prev_operational_area_id as from_area_id,
            ul.operational_area_id as to_area_id,
            ul.prev_observation_id as from_observation_id,
            ul.observation_id as to_observation_id,
            ul.observation_date as redeployment_date,
            EXTRACT(DAY FROM ul.observation_date - ul.prev_observation_date)::INTEGER as days_between,
            (ul.position_sequence = 2) as is_first_deployment
        FROM unit_locations ul
        WHERE ul.operational_area_id != ul.prev_operational_area_id
          AND ul.prev_operational_area_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 
              FROM redeployment_events re 
              WHERE re.unit_key = ul.unit_key 
                AND re.to_observation_id = ul.observation_id
          )
    ),
    -- Detect tactical relocations (within same operational area)
    tactical_relocations AS (
        SELECT 
            ul.unit_key,
            ul.unit_name,
            ul.prev_tactical_area_id as from_tactical_id,
            ul.tactical_area_id as to_tactical_id,
            ul.operational_area_id,
            ul.prev_observation_id as from_observation_id,
            ul.observation_id as to_observation_id,
            ul.observation_date as relocation_date,
            EXTRACT(DAY FROM ul.observation_date - ul.prev_observation_date)::INTEGER as days_between,
            LAG(ul.tactical_area_type) OVER (
                PARTITION BY ul.unit_key 
                ORDER BY ul.observation_date
            ) as from_area_type,
            ul.tactical_area_type as to_area_type
        FROM unit_locations ul
        WHERE ul.operational_area_id = ul.prev_operational_area_id  -- Same operational area
          AND ul.tactical_area_id != ul.prev_tactical_area_id  -- Different tactical area
          AND ul.prev_tactical_area_id IS NOT NULL
          AND ul.tactical_area_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 
              FROM tactical_relocation_events tre 
              WHERE tre.unit_key = ul.unit_key 
                AND tre.to_observation_id = ul.observation_id
          )
    )
    -- Insert operational redeployments
    INSERT INTO redeployment_events (
        unit_key,
        unit_name,
        from_area_id,
        to_area_id,
        from_observation_id,
        to_observation_id,
        redeployment_date,
        days_between,
        is_first_deployment
    )
    SELECT * FROM operational_redeployments;
    
    -- Insert tactical relocations
    INSERT INTO tactical_relocation_events (
        unit_key,
        unit_name,
        from_tactical_area_id,
        to_tactical_area_id,
        from_area_type,
        to_area_type,
        operational_area_id,
        from_observation_id,
        to_observation_id,
        relocation_date,
        days_between,
        movement_type
    )
    SELECT 
        tr.unit_key,
        tr.unit_name,
        tr.from_tactical_id,
        tr.to_tactical_id,
        tr.from_area_type,
        tr.to_area_type,
        tr.operational_area_id,
        tr.from_observation_id,
        tr.to_observation_id,
        tr.relocation_date,
        tr.days_between,
        CASE 
            WHEN tr.from_area_type = 'frontal' AND tr.to_area_type = 'rear' THEN 'front_to_rear'
            WHEN tr.from_area_type = 'rear' AND tr.to_area_type = 'frontal' THEN 'rear_to_front'
            WHEN tr.from_area_type = tr.to_area_type THEN 'lateral'
            WHEN tr.from_area_type IS NULL THEN 'initial_tactical'
            ELSE 'lateral'
        END as movement_type
    FROM tactical_relocations tr;
    
    -- Return combined results
    RETURN QUERY
    SELECT 
        re.event_id as movement_id,
        'OPERATIONAL'::VARCHAR(20) as movement_category,
        re.unit_key,
        re.unit_name,
        (SELECT name FROM spatial_ref.operational_areas WHERE area_id = re.from_area_id)::VARCHAR(254) as from_location,
        (SELECT name FROM spatial_ref.operational_areas WHERE area_id = re.to_area_id)::VARCHAR(254) as to_location,
        re.redeployment_date as movement_date,
        re.days_between,
        ('Operational redeployment' || 
         CASE WHEN re.is_first_deployment THEN ' (initial deployment)' ELSE '' END)::TEXT as movement_details
    FROM redeployment_events re
    WHERE re.detected_at >= CURRENT_TIMESTAMP - INTERVAL '1 minute'
    
    UNION ALL
    
    SELECT 
        tre.relocation_id as movement_id,
        'TACTICAL'::VARCHAR(20) as movement_category,
        tre.unit_key,
        tre.unit_name,
        (SELECT tactical_area_name FROM spatial_ref.tactical_areas WHERE tactical_area_id = tre.from_tactical_area_id)::VARCHAR(254) as from_location,
        (SELECT tactical_area_name FROM spatial_ref.tactical_areas WHERE tactical_area_id = tre.to_tactical_area_id)::VARCHAR(254) as to_location,
        tre.relocation_date as movement_date,
        tre.days_between,
        ('Tactical ' || tre.movement_type || ' relocation within ' || 
         (SELECT name FROM spatial_ref.operational_areas WHERE area_id = tre.operational_area_id))::TEXT as movement_details
    FROM tactical_relocation_events tre
    WHERE tre.detected_at >= CURRENT_TIMESTAMP - INTERVAL '1 minute';
END;
$$;


--
-- Name: FUNCTION detect_unit_movements(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.detect_unit_movements() IS 'Detects both operational redeployments and tactical relocations for Brigade/Regiment/Division units. Returns newly detected movements of both types. Reserves "um" alias for future unit_moves table.';


--
-- Name: disperse_unit_location(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.disperse_unit_location() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    tactical_geom geometry;
    flot_geom geometry;
    intersection_geom geometry;
    random_point geometry;
    max_attempts integer := 50;
    attempt_count integer := 0;
BEGIN
    -- Only generate location if location is NULL and tactical_area_id is provided
    IF NEW.location IS NULL AND NEW.tactical_area_id IS NOT NULL THEN

        -- Get the tactical area geometry
        SELECT geometry INTO tactical_geom
        FROM spatial_ref.tactical_areas
        WHERE tactical_area_id = NEW.tactical_area_id;

        IF tactical_geom IS NULL THEN
            RAISE NOTICE 'No geometry found for tactical_area_id: %', NEW.tactical_area_id;
            RETURN NEW;
        END IF;

        -- Get the FLOT boundary geometry
        SELECT ST_Union(geometry) INTO flot_geom
        FROM spatial_ref.flot_boundary
        WHERE active = TRUE;

        -- If no FLOT boundary exists, just use the tactical area
        IF flot_geom IS NULL THEN
            RAISE NOTICE 'No FLOT boundary found, using tactical area only';
            intersection_geom := tactical_geom;
        ELSE
            -- Calculate intersection of tactical area and FLOT boundary
            intersection_geom := ST_Intersection(tactical_geom, flot_geom);

            -- If no intersection, fall back to tactical area only
            IF intersection_geom IS NULL OR ST_IsEmpty(intersection_geom) THEN
                RAISE NOTICE 'No intersection between tactical area % and FLOT boundary, using tactical area only', NEW.tactical_area_id;
                intersection_geom := tactical_geom;
            END IF;
        END IF;

        -- Generate a random point within the intersection geometry
        LOOP
            random_point := ST_GeneratePoints(intersection_geom, 1);
            random_point := ST_PointN(ST_GeometryN(random_point, 1), 1);

            IF ST_Within(random_point, intersection_geom) THEN
                EXIT;
            END IF;

            attempt_count := attempt_count + 1;
            IF attempt_count >= max_attempts THEN
                random_point := ST_Centroid(intersection_geom);
                RAISE NOTICE 'Failed to generate random point after % attempts, using centroid for tactical_area_id: %',
                    max_attempts, NEW.tactical_area_id;
                EXIT;
            END IF;
        END LOOP;

        -- Set the generated location
        NEW.location := random_point;

        RAISE NOTICE 'Generated dispersed location for unit % at tactical_area_id %: POINT(% %)',
            NEW.unit_key, NEW.tactical_area_id, ST_X(random_point), ST_Y(random_point);
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: execute_spatial_update(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.execute_spatial_update() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tactical_processed INTEGER;
    v_operational_processed INTEGER;
    v_result TEXT;
BEGIN
    -- Validate first
    PERFORM validate_staging_data();
    
    -- Process updates
    SELECT COUNT(*) INTO v_tactical_processed
    FROM process_tactical_areas_update();
    
    SELECT COUNT(*) INTO v_operational_processed  
    FROM process_operational_areas_update();
    
    v_result := format('Update complete: %s tactical changes, %s operational changes', 
                       v_tactical_processed, v_operational_processed);
    
    -- Clear staging tables
    TRUNCATE spatial_ref.tactical_areas_staging;
    TRUNCATE spatial_ref.operational_areas_staging;
    
    RETURN v_result;
END;
$$;


--
-- Name: find_facility_associated_maids(character varying, integer, integer, integer); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.find_facility_associated_maids(p_facility_key character varying, p_detection_radius_m integer DEFAULT 5000, p_minimum_detections integer DEFAULT 10, p_minimum_days integer DEFAULT 3) RETURNS TABLE(maid_id character varying, detection_count bigint, detection_days bigint, first_seen timestamp without time zone, last_seen timestamp without time zone, avg_quality double precision, suggested_confidence character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    facility_location GEOMETRY;
BEGIN
    SELECT location INTO facility_location
    FROM russian_facilities 
    WHERE facility_key = p_facility_key;
    
    IF facility_location IS NULL THEN
        RAISE EXCEPTION 'Facility % not found', p_facility_key;
    END IF;
    
    RETURN QUERY
    SELECT 
        mp.maid_id,
        COUNT(*) as detection_count,
        COUNT(DISTINCT DATE(mp.timestamp)) as detection_days,
        MIN(mp.timestamp) as first_seen,
        MAX(mp.timestamp) as last_seen,
        AVG(mp.overall_confidence) as avg_quality,
        CASE 
            WHEN COUNT(*) >= 50 AND COUNT(DISTINCT DATE(mp.timestamp)) >= 15 
                 AND AVG(mp.overall_confidence) >= 0.7 THEN 'High'
            WHEN COUNT(*) >= 20 AND COUNT(DISTINCT DATE(mp.timestamp)) >= 7 THEN 'Medium'
            ELSE 'Low'
        END::VARCHAR(20) as suggested_confidence
    FROM maid_positions mp
    WHERE ST_DWithin(mp.location::geography, facility_location::geography, p_detection_radius_m)
      AND mp.location_quality IN ('HIGH', 'MEDIUM')
    GROUP BY mp.maid_id
    HAVING COUNT(*) >= p_minimum_detections 
       AND COUNT(DISTINCT DATE(mp.timestamp)) >= p_minimum_days
    ORDER BY detection_count DESC, detection_days DESC;
END;
$$;


--
-- Name: find_temporary_unit_keys(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.find_temporary_unit_keys() RETURNS TABLE(unit_key character varying, unit_name character varying, mun_number character varying, unit_type character varying, parent_unit character varying, position_count bigint, last_observed timestamp without time zone, has_maid_associations boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ru.unit_key,
        ru.unit_name,
        ru.mun_number,
        ru.unit_type,
        ru.parent_unit,
        COUNT(DISTINCT up.observation_id) AS position_count,
        MAX(up.observation_date) AS last_observed,
        EXISTS(SELECT 1 FROM maid_orbat_associations moa WHERE moa.associated_unit_key = ru.unit_key) AS has_maid_associations
    FROM russian_units ru
    LEFT JOIN unit_positions up ON ru.unit_key = up.unit_key
    WHERE ru.unit_key LIKE 'y%'
    GROUP BY ru.unit_key, ru.unit_name, ru.mun_number, ru.unit_type, ru.parent_unit
    ORDER BY position_count DESC, last_observed DESC NULLS LAST;
END;
$$;


--
-- Name: generate_unknown_unit_key(character); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.generate_unknown_unit_key(p_category character) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    next_serial INTEGER;
BEGIN
    IF p_category NOT IN ('a', 'b') THEN
        RAISE EXCEPTION 'Invalid category: %. Must be ''a'' or ''b''', p_category;
    END IF;
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(unknown_unit_key FROM 3) AS INTEGER)), 0) + 1
    INTO next_serial
    FROM unknown_units
    WHERE unknown_unit_key LIKE 'z' || p_category || '%';
    
    RETURN format('z%s%s', p_category, LPAD(next_serial::TEXT, 5, '0'));
END;
$$;


--
-- Name: get_maid_current_associations(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_maid_current_associations(target_maid_id character varying) RETURNS TABLE(unit_key character varying, unit_name character varying, confidence character varying, method character varying, since timestamp without time zone, evidence text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        moa.associated_unit_key,
        ru.unit_name,
        moa.association_confidence,
        moa.association_method,
        moa.association_date_start,
        moa.supporting_evidence
    FROM maid_orbat_associations moa
    LEFT JOIN russian_units ru ON moa.associated_unit_key = ru.unit_key
    WHERE moa.maid_id = target_maid_id 
      AND moa.association_date_end IS NULL
    ORDER BY moa.association_date_start DESC;
END;
$$;


--
-- Name: get_maid_id_by_alias(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_maid_id_by_alias(alias_name character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    target_maid_id VARCHAR(36);
BEGIN
    SELECT maid_id INTO target_maid_id
    FROM maid_registry 
    WHERE maid_alias = alias_name;
    
    RETURN target_maid_id;
END;
$$;


--
-- Name: get_maid_partition_info(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_maid_partition_info() RETURNS TABLE(partition_name text, record_count bigint, unique_maids bigint, size_mb double precision)
    LANGUAGE plpgsql
    AS $$
DECLARE
    partition_record RECORD;
BEGIN
    FOR partition_record IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE tablename LIKE 'maid_positions_p%'
        ORDER BY tablename
    LOOP
        RETURN QUERY
        EXECUTE format('
            SELECT 
                %L::TEXT as partition_name,
                COUNT(*)::BIGINT as record_count,
                COUNT(DISTINCT maid_id)::BIGINT as unique_maids,
                (pg_total_relation_size(%L) / 1024.0 / 1024.0)::DOUBLE PRECISION as size_mb
            FROM %I.%I',
            partition_record.tablename,
            partition_record.schemaname || '.' || partition_record.tablename,
            partition_record.schemaname,
            partition_record.tablename
        );
    END LOOP;
END;
$$;


--
-- Name: get_maid_positions_by_alias(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_maid_positions_by_alias(alias_name character varying) RETURNS TABLE(maid_observation_id bigint, maid_id character varying, time_stamp timestamp without time zone, location public.geometry, location_quality character varying, operational_relevance character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT mp.maid_observation_id, mp.maid_id, mp.time_stamp, mp.location, 
           mp.location_quality, mp.operational_relevance
    FROM maid_positions mp
    JOIN maid_registry mr ON mp.maid_id = mr.maid_id
    WHERE mr.maid_alias = alias_name
    ORDER BY mp.time_stamp DESC;
END;
$$;


--
-- Name: get_unit_hierarchy(text); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_unit_hierarchy(parent_unit_name text) RETURNS TABLE(unit_key character varying, unit_name character varying, parent_unit character varying, hierarchy_level integer, last_observed timestamp without time zone, current_operational_area character varying, hierarchy_display text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE unit_hierarchy AS (
        SELECT ru.unit_key, ru.unit_name, ru.parent_unit, 1 as level
        FROM russian_units ru 
        WHERE ru.unit_name = parent_unit_name
        UNION ALL
        SELECT ru.unit_key, ru.unit_name, ru.parent_unit, uh.level + 1
        FROM russian_units ru
        JOIN unit_hierarchy uh ON ru.parent_unit = uh.unit_name
    )
    SELECT 
        uh.unit_key,
        uh.unit_name,
        uh.parent_unit,
        uh.level as hierarchy_level,
        ru.last_observed,
        oa.name as current_operational_area, 
        REPEAT('  ', uh.level - 1) || uh.unit_name as hierarchy_display
    FROM unit_hierarchy uh
    JOIN russian_units ru ON uh.unit_key = ru.unit_key
    LEFT JOIN spatial_ref.operational_areas oa ON ru.current_operational_area_id = oa.area_id
    ORDER BY uh.level, uh.unit_name;
END;
$$;


--
-- Name: get_unit_hierarchy_with_symbology(text); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_unit_hierarchy_with_symbology(parent_unit_name text) RETURNS TABLE(unit_key character varying, unit_name character varying, mun_number character varying, parent_unit character varying, hierarchy_level integer, hierarchy_display text, current_lat double precision, current_long double precision, last_observed timestamp without time zone, location public.geometry, identity_ integer, context integer, symbolset integer, symbolentity integer, modifier1 integer, modifier2 integer, specialentitysubtype integer, echelon integer, status integer, hq_indicator integer, uniquedesignation character varying, higherformation character varying, reinforced character varying, combateffectiveness character varying, specialheadquarters integer, echelonlabel character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE unit_hierarchy AS (
        SELECT ru.unit_key, ru.unit_name, ru.parent_unit, 1 as level
        FROM russian_units ru 
        WHERE ru.unit_name = parent_unit_name
        
        UNION ALL
        
        SELECT ru.unit_key, ru.unit_name, ru.parent_unit, uh.level + 1
        FROM russian_units ru
        JOIN unit_hierarchy uh ON ru.parent_unit = uh.unit_name
    )
    SELECT 
        uh.unit_key,
        uh.unit_name,
        ru.mun_number,
        uh.parent_unit,
        uh.level as hierarchy_level,
        REPEAT('  ', uh.level - 1) || uh.unit_name as hierarchy_display,
        ru.current_lat,
        ru.current_long,
        ru.last_observed,
        CASE 
            WHEN ru.current_lat IS NOT NULL AND ru.current_long IS NOT NULL 
            THEN ST_SetSRID(ST_MakePoint(ru.current_long, ru.current_lat), 4326)
            ELSE NULL 
        END as location,
        -- NATO symbology fields
        ru.identity_,
        ru.context,
        ru.symbolset,
        ru.symbolentity,
        ru.modifier1,
        ru.modifier2,
        ru.specialentitysubtype,
        ru.echelon,
        ru.status,
        ru.hq_indicator,
        ru.uniquedesignation,
        ru.higherformation,
        ru.reinforced,
        ru.operational_condition,
        ru.specialheadquarters,
        ru.echelonlabel
    FROM unit_hierarchy uh
    JOIN russian_units ru ON uh.unit_key = ru.unit_key
    ORDER BY uh.level, uh.unit_name;
END;
$$;


--
-- Name: get_unit_military_district(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_unit_military_district(p_unit_key character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    current_higher_formation VARCHAR(20);
    current_parent_unit VARCHAR(100);
    iteration_count INTEGER := 0;
    max_iterations INTEGER := 20;  -- Prevent infinite loops
BEGIN
    -- Start with the given unit
    SELECT higherformation, parent_unit 
    INTO current_higher_formation, current_parent_unit
    FROM russian_units 
    WHERE unit_key = p_unit_key;
    
    -- If unit doesn't exist, return UNK
    IF NOT FOUND THEN
        RETURN 'UNK';
    END IF;
    
    -- Traverse up the hierarchy
    LOOP
        iteration_count := iteration_count + 1;
        
        -- Safety check to prevent infinite loops
        IF iteration_count > max_iterations THEN
            RETURN 'UNK';
        END IF;
        
        -- Check if current higherformation matches a known Military District
        IF current_higher_formation IN ('MMD', 'LMD', 'CMD', 'SMD', 'EMD', 'VDV HQ') THEN
            RETURN current_higher_formation;
        END IF;
        
        -- If no parent_unit, we've reached the top without finding a district
        IF current_parent_unit IS NULL THEN
            RETURN 'UNK';
        END IF;
        
        -- Move up to the parent unit
        SELECT higherformation, parent_unit 
        INTO current_higher_formation, current_parent_unit
        FROM russian_units 
        WHERE unit_name = current_parent_unit;
        
        -- If parent doesn't exist in the table, return UNK
        IF NOT FOUND THEN
            RETURN 'UNK';
        END IF;
        
    END LOOP;
END;
$$;


--
-- Name: get_unit_movement_history(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_unit_movement_history(target_unit_key character varying) RETURNS TABLE(observation_id integer, unit_key character varying, unit_name character varying, mun_number character varying, observation_date timestamp without time zone, location public.geometry, latitude double precision, longitude double precision, adm4_pcode character varying, settlement_name character varying, confidence_level character varying, source_type character varying, action character varying, position_sequence bigint, identity_ integer, context integer, symbolset integer, symbolentity integer, modifier1 integer, modifier2 integer, specialentitysubtype integer, echelon integer, status integer, hq_indicator integer, uniquedesignation character varying, higherformation character varying, reinforced character varying, combateffectiveness character varying, specialheadquarters integer, echelonlabel character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        umh.observation_id,
        umh.unit_key,
        umh.unit_name,
        umh.mun_number,
        umh.observation_date,
        umh.location,
        ST_Y(umh.location) as latitude,
        ST_X(umh.location) as longitude,
        umh.adm4_pcode,
        umh.settlement_name::VARCHAR(50),  -- Explicit cast to match
        umh.confidence_level,
        umh.source_type,
        umh.action,
        umh.position_sequence,
        umh.identity_,
        umh.context,
        umh.symbolset,
        umh.symbolentity,
        umh.modifier1,
        umh.modifier2,
        umh.specialentitysubtype,
        umh.echelon,
        umh.status,
        umh.hq_indicator,
        umh.uniquedesignation,
        umh.higherformation,
        umh.reinforced,
        umh.combateffectiveness,
        umh.specialheadquarters,
        umh.echelonlabel
    FROM unit_movement_history umh
    WHERE umh.unit_key = target_unit_key
    ORDER BY umh.observation_date;
END;
$$;


--
-- Name: get_unregistered_maids(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.get_unregistered_maids(status_filter character varying DEFAULT 'PENDING'::character varying) RETURNS TABLE(maid_id character varying, first_detected timestamp without time zone, latest_observation timestamp without time zone, observation_count integer, status character varying, assigned_analyst character varying, notes text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        um.maid_id,
        um.first_detected,
        um.latest_observation,
        um.observation_count,
        um.status,
        um.assigned_analyst,
        um.notes
    FROM unregistered_maids um
    WHERE um.status = status_filter OR status_filter IS NULL
    ORDER BY um.latest_observation DESC;
END;
$$;


--
-- Name: process_new_unit_position(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.process_new_unit_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    settlement_geom GEOMETRY;
    op_area_id INTEGER;
    op_area_name VARCHAR(254);
BEGIN
    -- Only process if operational_area_id is not already set
    IF NEW.operational_area_id IS NOT NULL THEN
        -- Operational area already set (maybe from update_unit_location_by_pcode_flot or detect_and_flag_redeployment)
        -- The detect_and_flag_redeployment trigger will handle redeployment detection
        RETURN NEW;
    END IF;
    
    -- Determine operational area based on what's available
    IF NEW.adm4_pcode IS NOT NULL THEN
        -- Get settlement centroid from PCODE
        -- **FIXED: Added spatial_ref schema reference**
        SELECT ST_Centroid(geom) INTO settlement_geom
        FROM spatial_ref.ukrainesettlements
        WHERE p_code = NEW.adm4_pcode
        LIMIT 1;
        
        IF settlement_geom IS NOT NULL THEN
            -- Get operational area from settlement centroid
            -- **FIXED: Added spatial_ref schema reference**
            SELECT oa.area_id, oa.area_name INTO op_area_id, op_area_name
            FROM spatial_ref.operational_areas oa
            WHERE ST_Within(settlement_geom, oa.area_geometry)
            ORDER BY oa.area_km2 ASC  -- Prefer smaller, more specific areas
            LIMIT 1;
            
            -- If not within any area, get nearest within 25km (typical brigade frontage)
            IF op_area_id IS NULL THEN
                SELECT oa.area_id, oa.area_name INTO op_area_id, op_area_name
                FROM spatial_ref.operational_areas oa
                WHERE ST_Distance(
                    ST_Transform(settlement_geom, 3857),
                    ST_Transform(oa.area_geometry, 3857)
                ) / 1000.0 <= 25
                ORDER BY ST_Distance(settlement_geom, oa.area_geometry)
                LIMIT 1;
            END IF;
        END IF;
        
    ELSIF NEW.location IS NOT NULL THEN
        -- Use actual location coordinates
        -- **FIXED: Added spatial_ref schema reference**
        SELECT oa.area_id, oa.area_name INTO op_area_id, op_area_name
        FROM spatial_ref.operational_areas oa
        WHERE ST_Within(NEW.location, oa.area_geometry)
        ORDER BY oa.area_km2 ASC  -- Prefer smaller, more specific areas
        LIMIT 1;
        
        -- If not within any area, get nearest within 25km
        IF op_area_id IS NULL THEN
            SELECT oa.area_id, oa.area_name INTO op_area_id, op_area_name
            FROM spatial_ref.operational_areas oa
            WHERE ST_Distance(
                ST_Transform(NEW.location, 3857),
                ST_Transform(oa.area_geometry, 3857)
            ) / 1000.0 <= 25
            ORDER BY ST_Distance(NEW.location, oa.area_geometry)
            LIMIT 1;
        END IF;
    END IF;
    
    -- Set the operational area ID (the new approach)
    NEW.operational_area_id := op_area_id;
    NEW.area_assignment_method := CASE 
        WHEN op_area_id IS NOT NULL THEN 'AUTO_SPATIAL'
        ELSE 'NONE_FOUND'
    END;
    
    -- Add note about which method was used
    IF op_area_id IS NOT NULL THEN
        NEW.notes := COALESCE(NEW.notes || ' | ', '') || 
                    'Auto-assigned to operational area: ' || op_area_name;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: FUNCTION process_new_unit_position(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.process_new_unit_position() IS 'Automatically assigns operational area based on PCODE or location. Runs before detect_and_flag_redeployment trigger.';


--
-- Name: process_operational_areas_update(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.process_operational_areas_update() RETURNS TABLE(action character varying, area_name character varying, details text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update existing areas with new geometries
    UPDATE spatial_ref.operational_areas oa
    SET 
        geom = oas.geom,
        shape_length = oas.shape__len,  -- Note double underscore
        shape_area = oas.shape__are,     -- Note double underscore
        updated_at = CURRENT_TIMESTAMP
    FROM spatial_ref.operational_areas_staging oas
    WHERE oa.name = TRIM(oas.name)
        AND NOT ST_Equals(oa.geom, oas.geom);
    
    -- Insert new areas
    INSERT INTO spatial_ref.operational_areas (
        name,
        geom,
        shape_length,
        shape_area
    )
    SELECT DISTINCT ON (name)
        TRIM(name),
        geom,
        shape__len,  -- Note double underscore
        shape__are    -- Note double underscore
    FROM spatial_ref.operational_areas_staging oas
    WHERE NOT EXISTS (
        SELECT 1 FROM spatial_ref.operational_areas oa
        WHERE oa.name = TRIM(oas.name)
    );
    
    -- Return summary
    RETURN QUERY
    SELECT 
        CASE 
            WHEN oa_old.area_id IS NULL THEN 'NEW'
            WHEN NOT ST_Equals(oa_old.geometry, oas.geom) THEN 'MODIFIED'
            ELSE 'UNCHANGED'
        END as action,
        TRIM(oas.name) as area_name,
        CASE 
            WHEN oa_old.area_id IS NULL THEN 'New operational area added'
            WHEN NOT ST_Equals(oa_old.geometry, oas.geom) THEN 'Geometry updated'
            ELSE 'No changes'
        END as details
    FROM spatial_ref.operational_areas_staging oas
    LEFT JOIN spatial_ref.operational_areas oa_old 
        ON oa_old.name = TRIM(oas.name);
END;
$$;


--
-- Name: process_tactical_areas_update(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.process_tactical_areas_update() RETURNS TABLE(action character varying, area_name character varying, area_type character varying, details text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Fix type values if needed
    UPDATE spatial_ref.tactical_areas_staging
    SET type = 'frontal'
    WHERE type = 'front';
    
    -- Create temp table for logging
    CREATE TEMP TABLE IF NOT EXISTS temp_update_log (
        action VARCHAR(20),
        area_name VARCHAR(255),
        area_type VARCHAR(50),
        details TEXT
    );
    
    -- Log new areas
    INSERT INTO temp_update_log (action, area_name, area_type, details)
    SELECT 
        'NEW',
        tas.tac_area_n,
        tas.type,
        'New tactical area detected'
    FROM spatial_ref.tactical_areas_staging tas
    WHERE NOT EXISTS (
        SELECT 1 FROM spatial_ref.tactical_areas ta
        WHERE ta.tactical_area_name = TRIM(tas.tac_area_n)
        AND ta.area_type = tas.type
    );
    
    -- Log modified areas (geometry changes)
    INSERT INTO temp_update_log (action, area_name, area_type, details)
    SELECT 
        'MODIFIED',
        tas.tac_area_n,
        tas.type,
        'Geometry updated'
    FROM spatial_ref.tactical_areas_staging tas
    JOIN spatial_ref.tactical_areas ta 
        ON ta.tactical_area_name = TRIM(tas.tac_area_n)
        AND ta.area_type = tas.type
    WHERE NOT ST_Equals(ta.geometry, tas.geom);
    
    -- Update existing areas with new geometries
    UPDATE spatial_ref.tactical_areas ta
    SET 
        geometry = tas.geom,
        shape_length = tas.shape_leng,
        shape_area = tas.shape_area,
        updated_at = CURRENT_TIMESTAMP
    FROM spatial_ref.tactical_areas_staging tas
    WHERE ta.tactical_area_name = TRIM(tas.tac_area_n)
        AND ta.area_type = tas.type
        AND NOT ST_Equals(ta.geometry, tas.geom);
    
    -- Insert new areas
    WITH new_areas AS (
        INSERT INTO spatial_ref.tactical_areas (
            tactical_area_name,
            area_type,
            geometry,
            shape_length,
            shape_area
        )
        SELECT DISTINCT ON (tac_area_n, type)
            TRIM(tac_area_n),
            type,
            geom,
            shape_leng,
            shape_area
        FROM spatial_ref.tactical_areas_staging tas
        WHERE NOT EXISTS (
            SELECT 1 FROM spatial_ref.tactical_areas ta
            WHERE ta.tactical_area_name = TRIM(tas.tac_area_n)
            AND ta.area_type = tas.type
        )
        RETURNING tactical_area_id, tactical_area_name
    )
    -- Handle operational area associations for new areas
    INSERT INTO spatial_ref.tactical_operational_associations (
        tactical_area_id,
        operational_area_id
    )
    SELECT DISTINCT
        na.tactical_area_id,
        oa.area_id  -- Corrected from operational_area_id
    FROM new_areas na
    JOIN spatial_ref.tactical_areas_staging tas 
        ON na.tactical_area_name = TRIM(tas.tac_area_n)
    JOIN spatial_ref.operational_areas oa 
        ON TRIM(tas.operationa) = oa.name  -- Corrected from operational_area_name
    WHERE tas.operationa IS NOT NULL 
        AND TRIM(tas.operationa) != ''
        AND tas.operationa != '[null]';
    
    -- Return summary
    RETURN QUERY
    SELECT * FROM temp_update_log;
    
    DROP TABLE temp_update_log;
END;
$$;


--
-- Name: promote_unknown_unit(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.promote_unknown_unit(p_unknown_unit_key character varying, p_new_unit_key character varying, p_unit_name character varying, p_mun_number character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
    unk_record RECORD;
BEGIN
    -- Validate keys
    IF p_unknown_unit_key !~ '^z[ab]\d{5}$' THEN
        RAISE EXCEPTION 'Invalid unknown_unit_key: %. Must be za##### or zb#####', p_unknown_unit_key;
    END IF;
    
    IF p_new_unit_key !~ '^[xy]\d{5}$' THEN
        RAISE EXCEPTION 'Invalid new unit_key: %. Must be x##### or y#####', p_new_unit_key;
    END IF;
    
    -- Get unknown unit data
    SELECT * INTO unk_record FROM unknown_units WHERE unknown_unit_key = p_unknown_unit_key;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown unit % not found', p_unknown_unit_key;
    END IF;
    
    -- Create new russian_units entry, inheriting symbology
    INSERT INTO russian_units (
        unit_key, unit_name, mun_number, unit_type, parent_unit_key,
        identity_, context, symbolset, symbolentity,
        modifier1, modifier2, specialentitysubtype, echelon, hq_indicator,
        uniquedesignation, higherformation,
        current_lat, current_long, last_observed,
        operational_condition, status, reinforced, current_action,
        created_date
    ) VALUES (
        p_new_unit_key, p_unit_name, p_mun_number, 
        COALESCE(unk_record.element_type, 'Unknown'), unk_record.parent_unit_key,
        unk_record.identity_, unk_record.context, unk_record.symbolset, unk_record.symbolentity,
        unk_record.modifier1, unk_record.modifier2, unk_record.specialentitysubtype, 
        unk_record.echelon, unk_record.hq_indicator,
        p_new_unit_key, COALESCE(unk_record.higherformation, p_new_unit_key),
        unk_record.current_lat, unk_record.current_long, unk_record.last_observed,
        unk_record.operational_condition, unk_record.status, unk_record.reinforced,
        unk_record.current_action,
        CURRENT_TIMESTAMP
    );
    
    -- Mark as promoted
    UPDATE unknown_units
    SET promoted_to_unit_key = p_new_unit_key,
        promoted_date = CURRENT_TIMESTAMP,
        promotion_reason = format('Confirmed as %s (%s)', p_unit_name, p_mun_number)
    WHERE unknown_unit_key = p_unknown_unit_key;
    
    -- Relink all mentions
    UPDATE unit_mentions
    SET unit_key = p_new_unit_key, unknown_unit_key = NULL
    WHERE unknown_unit_key = p_unknown_unit_key;
    
    -- Migrate positions
    INSERT INTO unit_positions (
        unit_key, observation_date, location, tactical_area_id,
        operational_condition, status, reinforced, source_type, notes, analyst, created_date
    )
    SELECT 
        p_new_unit_key, observation_date, location, tactical_area_id,
        operational_condition, status, reinforced, 'promoted',
        format('Migrated from unknown unit %s: %s', p_unknown_unit_key, unk_record.provisional_name),
        analyst, created_date
    FROM unit_mentions
    WHERE unknown_unit_key = p_unknown_unit_key
    AND review_status = 'approved' AND location IS NOT NULL;
    
    RETURN p_new_unit_key;
END;
$_$;


--
-- Name: FUNCTION promote_unknown_unit(p_unknown_unit_key character varying, p_new_unit_key character varying, p_unit_name character varying, p_mun_number character varying); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.promote_unknown_unit(p_unknown_unit_key character varying, p_new_unit_key character varying, p_unit_name character varying, p_mun_number character varying) IS 'Promotes unknown unit (za/zb key) to confirmed unit (x/y key). Migrates all symbology, positions, and mentions.';


--
-- Name: register_maid(character varying, character varying, character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.register_maid(target_maid_id character varying, alias_name character varying, priority character varying DEFAULT 'MEDIUM'::character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Insert or update the registry
    INSERT INTO maid_registry (maid_id, maid_alias, priority_level)
    VALUES (target_maid_id, alias_name, priority)
    ON CONFLICT (maid_id) DO UPDATE SET
        maid_alias = EXCLUDED.maid_alias,
        priority_level = EXCLUDED.priority_level,
        updated_date = CURRENT_TIMESTAMP;
    
    -- Auto-populate statistics from maid_positions
    PERFORM backfill_maid_registry_stats(target_maid_id);
    
    -- If this MAID was in unregistered_maids, mark it as registered
    UPDATE unregistered_maids
    SET 
        status = 'REGISTERED',
        assigned_analyst = CURRENT_USER,
        notes = 'Registered as "' || alias_name || '"'
    WHERE maid_id = target_maid_id
      AND status = 'PENDING';
    
    RETURN TRUE;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Alias % already exists for different MAID', alias_name;
        RETURN FALSE;
END;
$$;


--
-- Name: FUNCTION register_maid(target_maid_id character varying, alias_name character varying, priority character varying); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.register_maid(target_maid_id character varying, alias_name character varying, priority character varying) IS 'Creates or updates a MAID registry entry with alias and priority. 
Automatically populates statistics and clears unregistered_maids alerts.';


--
-- Name: search_units_for_key_update(text, integer, boolean); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.search_units_for_key_update(search_pattern text DEFAULT 'y%'::text, min_positions integer DEFAULT 0, include_no_positions boolean DEFAULT true) RETURNS TABLE(unit_key character varying, unit_name character varying, mun_number character varying, unit_type character varying, parent_unit character varying, echelon_name character varying, position_count bigint, last_observed timestamp without time zone, operational_area character varying, has_maid_associations boolean, has_redeployments boolean, suggested_new_key text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ru.unit_key,
        ru.unit_name,
        ru.mun_number,
        ru.unit_type,
        ru.parent_unit,
        ec.description AS echelon_name,
        COUNT(DISTINCT up.observation_id) AS position_count,
        MAX(up.observation_date) AS last_observed,
        ru.operational_area,
        EXISTS(SELECT 1 FROM maid_orbat_associations moa WHERE moa.associated_unit_key = ru.unit_key) AS has_maid_associations,
        EXISTS(SELECT 1 FROM redeployment_events re WHERE re.unit_key = ru.unit_key) AS has_redeployments,
        CASE 
            WHEN ru.mun_number IS NOT NULL THEN 'x' || ru.mun_number
            ELSE 'MUN number needed'
        END AS suggested_new_key
    FROM russian_units ru
    LEFT JOIN unit_positions up ON ru.unit_key = up.unit_key
    LEFT JOIN reference.echelon_codes ec ON ru.echelon = ec.code
    WHERE ru.unit_key LIKE search_pattern
    GROUP BY ru.unit_key, ru.unit_name, ru.mun_number, ru.unit_type, ru.parent_unit, 
             ec.description, ru.operational_area
    HAVING (include_no_positions OR COUNT(DISTINCT up.observation_id) > 0)
       AND COUNT(DISTINCT up.observation_id) >= min_positions
    ORDER BY position_count DESC, last_observed DESC NULLS LAST;
END;
$$;


--
-- Name: FUNCTION search_units_for_key_update(search_pattern text, min_positions integer, include_no_positions boolean); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.search_units_for_key_update(search_pattern text, min_positions integer, include_no_positions boolean) IS 'Advanced search for units needing key updates with filtering options
Usage examples:
  SELECT * FROM search_units_for_key_update();  -- All temp keys
  SELECT * FROM search_units_for_key_update(''y%'', 5);  -- Only units with 5+ positions
  SELECT * FROM search_units_for_key_update(''y%'', 0, false);  -- Exclude units with no positions';


--
-- Name: sync_current_facility_to_history(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.sync_current_facility_to_history() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- End ongoing associations that don't match current assignment
    UPDATE facility_orbat_associations 
    SET association_end_date = CURRENT_TIMESTAMP
    FROM russian_units ru
    WHERE facility_orbat_associations.unit_key = ru.unit_key
      AND facility_orbat_associations.association_end_date IS NULL
      AND facility_orbat_associations.facility_key != ru.current_facility_key;
    
    -- Insert new associations for current assignments
    INSERT INTO facility_orbat_associations (
        facility_key, unit_key, association_type, association_confidence,
        association_start_date, identification_method
    )
    SELECT 
        ru.current_facility_key,
        ru.unit_key,
        ru.facility_assignment_type,
        ru.facility_assignment_confidence,
        ru.facility_assignment_date,
        'CURRENT_ASSIGNMENT_SYNC'
    FROM russian_units ru
    WHERE ru.current_facility_key IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM facility_orbat_associations foa
          WHERE foa.unit_key = ru.unit_key
            AND foa.facility_key = ru.current_facility_key
            AND foa.association_end_date IS NULL
      );
END;
$$;


--
-- Name: sync_russian_units_geometry(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.sync_russian_units_geometry() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- When lat or long changes, update geometry
    IF NEW.current_lat IS NOT NULL AND NEW.current_long IS NOT NULL THEN
        NEW.shape = ST_SetSRID(ST_MakePoint(NEW.current_long, NEW.current_lat), 4326);
    ELSE
        NEW.shape = NULL;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: trigger_update_coordinates(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.trigger_update_coordinates() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM public.update_unit_coordinates();
    RETURN NULL;
END;
$$;


--
-- Name: unit_hierarchy(text); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.unit_hierarchy(parent_unit_name text) RETURNS TABLE(unit_key character varying, unit_name text, parent_unit text, hierarchy_level integer, current_lat double precision, current_long double precision, last_observed timestamp without time zone, hierarchy_display text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE unit_hierarchy AS (
        -- Base case: Start with the specified parent unit
        SELECT 
            ru.unit_key, 
            ru.unit_name, 
            ru.parent_unit, 
            1 as level
        FROM russian_units ru
        WHERE ru.unit_name = parent_unit_name
        
        UNION ALL
        
        -- Recursive case: Find units whose parent is in our hierarchy
        SELECT 
            ru.unit_key, 
            ru.unit_name, 
            ru.parent_unit, 
            uh.level + 1
        FROM russian_units ru
        JOIN unit_hierarchy uh ON ru.parent_unit = uh.unit_name
    )
    SELECT 
        uh.unit_key,
        uh.unit_name,
        uh.parent_unit,
        uh.level as hierarchy_level,
        ru.current_lat,
        ru.current_long,
        ru.last_observed,
        REPEAT('  ', uh.level - 1) || uh.unit_name as hierarchy_display
    FROM unit_hierarchy uh
    JOIN russian_units ru ON uh.unit_key = ru.unit_key
    ORDER BY uh.level, uh.unit_name;
END;
$$;


--
-- Name: update_locations_with_pcode_centroids(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_locations_with_pcode_centroids() RETURNS TABLE(updated_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    update_count BIGINT := 0;
BEGIN
    -- UPDATED: Reference spatial_ref schema
    UPDATE unit_positions up
    SET location = ST_Centroid(us.geom)
    FROM spatial_ref.ukrainesettlements us
    WHERE up.location IS NULL
      AND up.adm4_pcode IS NOT NULL
      AND up.adm4_pcode = us.adm4_pcode;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    
    RETURN QUERY SELECT update_count;
END;
$$;


--
-- Name: FUNCTION update_locations_with_pcode_centroids(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.update_locations_with_pcode_centroids() IS 'Updates NULL locations using PCODE centroids from spatial_ref.ukrainesettlements';


--
-- Name: update_maid_registry_stats(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_maid_registry_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    registry_exists BOOLEAN;
BEGIN
    -- Check if MAID exists in registry
    SELECT EXISTS(
        SELECT 1 FROM maid_registry WHERE maid_id = NEW.maid_id
    ) INTO registry_exists;
    
    -- If MAID is in registry, update statistics
    IF registry_exists THEN
        UPDATE maid_registry
        SET 
            -- Update first_observed if this is earlier
            first_observed = CASE 
                WHEN first_observed IS NULL OR NEW.timestamp < first_observed 
                THEN NEW.timestamp 
                ELSE first_observed 
            END,
            -- Update last_observed if this is later
            last_observed = CASE 
                WHEN last_observed IS NULL OR NEW.timestamp > last_observed 
                THEN NEW.timestamp 
                ELSE last_observed 
            END,
            -- Increment observation count
            total_observations = COALESCE(total_observations, 0) + 1,
            -- Update the registry modification timestamp
            updated_date = CURRENT_TIMESTAMP
        WHERE maid_id = NEW.maid_id;
        
    -- If MAID not in registry, flag it for analyst review
    ELSE
        -- Insert or update the unregistered MAID alert
        INSERT INTO unregistered_maids (
            maid_id,
            observation_count,
            latest_observation
        ) VALUES (
            NEW.maid_id,
            1,
            NEW.timestamp
        )
        ON CONFLICT (maid_id) DO UPDATE SET
            observation_count = unregistered_maids.observation_count + 1,
            latest_observation = CASE 
                WHEN NEW.timestamp > unregistered_maids.latest_observation 
                THEN NEW.timestamp 
                ELSE unregistered_maids.latest_observation 
            END;
        
        -- Log warning (appears in PostgreSQL logs)
        RAISE NOTICE 'UNREGISTERED MAID DETECTED: % - Added to unregistered_maids table for analyst review', NEW.maid_id;
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: FUNCTION update_maid_registry_stats(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.update_maid_registry_stats() IS 'Trigger function that updates maid_registry statistics when new positions are inserted. 
Flags unregistered MAIDs for analyst review.';


--
-- Name: update_military_districts(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_military_districts() RETURNS TABLE(district_name text, units_updated integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    districts text[] := ARRAY[
        'Moscow Military District',
        'Leningrad Military District', 
        'Southern Military District',
        'Central Military District',
        'Eastern Military District'
    ];
    district text;
    update_count integer;
BEGIN
    -- Loop through each military district
    FOREACH district IN ARRAY districts
    LOOP
        -- Update all units in this district's hierarchy
        UPDATE russian_units
        SET military_district = district
        WHERE unit_key IN (
            SELECT unit_key 
            FROM reference.get_unit_hierarchy(district)
        );
        
        -- Get count of updated rows
        GET DIAGNOSTICS update_count = ROW_COUNT;
        
        -- Return the district name and count
        district_name := district;
        units_updated := update_count;
        RETURN NEXT;
    END LOOP;
    
    RETURN;
END;
$$;


--
-- Name: update_spatial_areas(character varying); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_spatial_areas(p_update_type character varying) RETURNS TABLE(update_type character varying, total_processed integer, new_areas integer, modified_areas integer, unchanged_areas integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tactical_new INTEGER := 0;
    v_tactical_modified INTEGER := 0;
    v_operational_new INTEGER := 0;
    v_operational_modified INTEGER := 0;
BEGIN
    IF p_update_type IN ('tactical', 'both') THEN
        -- Process tactical areas
        SELECT COUNT(*) INTO v_tactical_new
        FROM process_tactical_areas_update()
        WHERE action = 'NEW';
        
        SELECT COUNT(*) INTO v_tactical_modified
        FROM process_tactical_areas_update()
        WHERE action = 'MODIFIED';
        
        -- Clear staging
        TRUNCATE spatial_ref.tactical_areas_update_staging;
    END IF;
    
    IF p_update_type IN ('operational', 'both') THEN
        -- Process operational areas
        SELECT COUNT(*) INTO v_operational_new
        FROM process_operational_areas_update()
        WHERE action = 'NEW';
        
        SELECT COUNT(*) INTO v_operational_modified
        FROM process_operational_areas_update()
        WHERE action = 'MODIFIED';
        
        -- Clear staging
        TRUNCATE spatial_ref.operational_areas_update_staging;
    END IF;
    
    RETURN QUERY
    SELECT 
        p_update_type,
        v_tactical_new + v_tactical_modified + v_operational_new + v_operational_modified,
        v_tactical_new + v_operational_new,
        v_tactical_modified + v_operational_modified,
        0;  -- Would need more logic to calculate unchanged
END;
$$;


--
-- Name: update_unit_coordinates(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_unit_coordinates() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE russian_units 
    SET 
        current_lat = ST_Y(subq.location_wgs84),
        current_long = ST_X(subq.location_wgs84),
        last_observed = subq.latest_date
    FROM (
        SELECT DISTINCT ON (unit_key)
            unit_key,
            location as location_wgs84,
            observation_date as latest_date
        FROM unit_positions 
        WHERE location IS NOT NULL
        ORDER BY unit_key, observation_date DESC
    ) subq
    WHERE russian_units.unit_key = subq.unit_key;
END;
$$;


--
-- Name: FUNCTION update_unit_coordinates(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.update_unit_coordinates() IS 'Updates current_lat, current_long, and last_observed in russian_units from latest position';


--
-- Name: update_unit_current_area(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_unit_current_area() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Sync based on current coordinates in russian_units
    UPDATE russian_units ru
    SET current_operational_area_id = oa.area_id
    FROM spatial_ref.operational_areas oa
    WHERE ST_Within(
        ST_SetSRID(ST_MakePoint(ru.current_long, ru.current_lat), 4326),
        oa.geom
    )
    AND ru.current_lat IS NOT NULL
    AND ru.current_long IS NOT NULL;
END;
$$;


--
-- Name: FUNCTION update_unit_current_area(); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.update_unit_current_area() IS 'Syncs current_operational_area_id from unit_positions to russian_units';


--
-- Name: update_unit_from_position(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_unit_from_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    unit_prefix VARCHAR(2);
    is_known_unit BOOLEAN;
    is_unknown_unit BOOLEAN;
    is_main_body BOOLEAN DEFAULT FALSE;
    mention_count INTEGER;
    has_command_changes BOOLEAN DEFAULT FALSE;
    new_parent_key VARCHAR(10);
    new_opcon_key VARCHAR(10);
    new_adcon_key VARCHAR(10);
    extracted_lat DOUBLE PRECISION;
    extracted_long DOUBLE PRECISION;
BEGIN
    unit_prefix := SUBSTRING(NEW.unit_key FROM 1 FOR 2);
    is_known_unit := (unit_prefix IN ('y', 'x') OR LEFT(NEW.unit_key, 1) IN ('y', 'x'));
    is_unknown_unit := (unit_prefix IN ('za', 'zb'));

    IF NOT is_known_unit AND NOT is_unknown_unit THEN
        RAISE NOTICE 'Unit key % does not match known (y*, x*) or unknown (za*, zb*) pattern. Skipping update.',
            NEW.unit_key;
        RETURN NEW;
    END IF;

    IF NEW.location IS NOT NULL THEN
        extracted_lat := ST_Y(NEW.location);
        extracted_long := ST_X(NEW.location);
    END IF;

    SELECT
        COUNT(*),
        BOOL_OR(COALESCE(um.is_main_body, FALSE)),
        BOOL_OR(um.new_parent_unit_key IS NOT NULL OR
                um.new_opcon_unit_key IS NOT NULL OR
                um.new_adcon_unit_key IS NOT NULL),
        MAX(um.new_parent_unit_key),
        MAX(um.new_opcon_unit_key),
        MAX(um.new_adcon_unit_key)
    INTO
        mention_count,
        is_main_body,
        has_command_changes,
        new_parent_key,
        new_opcon_key,
        new_adcon_key
    FROM unit_mentions um
    WHERE um.committed_to_position_id = NEW.observation_id;

    IF mention_count = 0 THEN
        is_main_body := TRUE;
        RAISE NOTICE 'No unit_mentions found for observation_id %. Assuming main body position.',
            NEW.observation_id;
    END IF;

    RAISE NOTICE 'Processing unit_key: % (is_known: %, is_unknown: %, is_main_body: %, has_command_changes: %)',
        NEW.unit_key, is_known_unit, is_unknown_unit, is_main_body, has_command_changes;

    IF is_known_unit THEN
        IF is_main_body THEN
            UPDATE public.russian_units
            SET
                current_lat = COALESCE(extracted_lat, current_lat),
                current_long = COALESCE(extracted_long, current_long),
                current_tactical_area_id = COALESCE(NEW.tactical_area_id, current_tactical_area_id),
                current_operational_area_id = COALESCE(NEW.operational_area_id, current_operational_area_id),
                operational_condition = COALESCE(NEW.operational_condition, operational_condition),
                status = COALESCE(NEW.status, status),
                reinforced = COALESCE(NEW.reinforced, reinforced),
                current_action = COALESCE(NEW.action, current_action),
                last_observed = NEW.observation_date,
                updated_date = CURRENT_TIMESTAMP,
                parent_unit_key = CASE
                    WHEN has_command_changes AND new_parent_key IS NOT NULL
                    THEN new_parent_key
                    ELSE parent_unit_key
                END,
                opcon_unit_key = CASE
                    WHEN has_command_changes AND new_opcon_key IS NOT NULL
                    THEN new_opcon_key
                    ELSE opcon_unit_key
                END,
                adcon_unit_key = CASE
                    WHEN has_command_changes AND new_adcon_key IS NOT NULL
                    THEN new_adcon_key
                    ELSE adcon_unit_key
                END
            WHERE unit_key = NEW.unit_key;

            IF FOUND THEN
                RAISE NOTICE 'Updated russian_units for % (main body): lat=%, long=%, tac_area=%, op_area=%, op_cond=%',
                    NEW.unit_key, extracted_lat, extracted_long,
                    NEW.tactical_area_id, NEW.operational_area_id, NEW.operational_condition;

                IF has_command_changes THEN
                    RAISE NOTICE 'Applied command changes for %: parent=%, opcon=%, adcon=%',
                        NEW.unit_key, new_parent_key, new_opcon_key, new_adcon_key;
                END IF;
            ELSE
                RAISE WARNING 'Unit key % not found in russian_units table!', NEW.unit_key;
            END IF;
        ELSE
            UPDATE public.russian_units
            SET
                operational_condition = COALESCE(NEW.operational_condition, operational_condition),
                status = COALESCE(NEW.status, status),
                current_action = COALESCE(NEW.action, current_action),
                updated_date = CURRENT_TIMESTAMP
            WHERE unit_key = NEW.unit_key;

            IF FOUND THEN
                RAISE NOTICE 'Updated russian_units for % (detached element): op_cond=%, status=%',
                    NEW.unit_key, NEW.operational_condition, NEW.status;
            END IF;
        END IF;
    END IF;

    IF is_unknown_unit THEN
        IF is_main_body THEN
            UPDATE public.unknown_units
            SET
                current_lat = COALESCE(extracted_lat, current_lat),
                current_long = COALESCE(extracted_long, current_long),
                tactical_area_id = COALESCE(NEW.tactical_area_id, tactical_area_id),
                operational_area_id = COALESCE(NEW.operational_area_id, operational_area_id),
                operational_condition = COALESCE(NEW.operational_condition, operational_condition),
                status = COALESCE(NEW.status, status),
                reinforced = COALESCE(NEW.reinforced, reinforced),
                last_observed = NEW.observation_date,
                parent_unit_key = CASE
                    WHEN has_command_changes AND new_parent_key IS NOT NULL
                    THEN new_parent_key
                    ELSE parent_unit_key
                END
            WHERE unknown_unit_key = NEW.unit_key;

            IF FOUND THEN
                RAISE NOTICE 'Updated unknown_units for % (main body): lat=%, long=%, tac_area=%, op_area=%, op_cond=%',
                    NEW.unit_key, extracted_lat, extracted_long,
                    NEW.tactical_area_id, NEW.operational_area_id, NEW.operational_condition;

                IF has_command_changes AND new_parent_key IS NOT NULL THEN
                    RAISE NOTICE 'Applied parent change for %: parent=%',
                        NEW.unit_key, new_parent_key;
                END IF;
            ELSE
                RAISE WARNING 'Unknown unit key % not found in unknown_units table!', NEW.unit_key;
            END IF;
        ELSE
            UPDATE public.unknown_units
            SET
                operational_condition = COALESCE(NEW.operational_condition, operational_condition),
                status = COALESCE(NEW.status, status),
                last_observed = NEW.observation_date
            WHERE unknown_unit_key = NEW.unit_key;

            IF FOUND THEN
                RAISE NOTICE 'Updated unknown_units for % (detached element): op_cond=%, status=%',
                    NEW.unit_key, NEW.operational_condition, NEW.status;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: update_unit_location_by_pcode_flot(character varying, character varying, integer, integer); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.update_unit_location_by_pcode_flot(target_unit_key character varying, amd4_pcode character varying, dispersion_radius_m integer DEFAULT 5000, max_attempts integer DEFAULT 50) RETURNS TABLE(unit_key character varying, new_lat double precision, new_lon double precision, settlement_name text, pcode text, attempts_used integer, within_flot boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    settlement_geom GEOMETRY;
    settlement_centroid GEOMETRY;
    settlement_name_var TEXT;
    flot_geom GEOMETRY;
    test_point GEOMETRY;
    attempt_count INTEGER := 0;
    point_within_flot BOOLEAN := FALSE;
    final_lat DOUBLE PRECISION;
    final_lon DOUBLE PRECISION;
    confidence VARCHAR(20);
    source_type_var VARCHAR(50);
BEGIN
    -- Get most recent FLOT boundary
    SELECT ST_Union(geom) INTO flot_geom
    FROM flot_boundary 
    WHERE import_date = (SELECT MAX(import_date) FROM flot_boundary);
    
    IF flot_geom IS NULL THEN
        RAISE EXCEPTION 'No FLOT boundary found. Import FLOT data first.';
    END IF;
    
    -- Get settlement geometry by PCODE
    -- **FIXED: Added spatial_ref schema reference**
    SELECT geom, name_en INTO settlement_geom, settlement_name_var
    FROM spatial_ref.ukrainesettlements
    WHERE p_code = amd4_pcode;
    
    IF settlement_geom IS NULL THEN
        RAISE EXCEPTION 'Settlement with PCODE % not found', amd4_pcode;
    END IF;
    
    -- Get settlement centroid
    settlement_centroid := ST_Centroid(settlement_geom);
    
    -- Try to generate a point within FLOT
    WHILE attempt_count < max_attempts LOOP
        attempt_count := attempt_count + 1;
        
        -- Generate random point within dispersion radius of settlement centroid
        test_point := ST_Project(
            settlement_centroid::geography,
            random() * dispersion_radius_m,
            random() * 2 * pi()
        )::geometry;
        
        -- Check if point is within FLOT (Russian-controlled territory)
        IF ST_Within(test_point, flot_geom) THEN
            point_within_flot := TRUE;
            EXIT;
        END IF;
    END LOOP;
    
    -- If no point found within FLOT after max attempts, use last generated point
    IF NOT point_within_flot THEN
        confidence := 'Low';
        source_type_var := 'PCODE_Assignment_No_FLOT';
    ELSE
        confidence := 'High';
        source_type_var := 'PCODE_Assignment_FLOT';
    END IF;
    
    -- Extract lat/lon from final point
    final_lat := ST_Y(test_point);
    final_lon := ST_X(test_point);
    
    -- Insert new position into unit_positions
    INSERT INTO unit_positions (
        unit_key,
        observation_date,
        location,
        amd4_pcode,
        confidence_level,
        source_type,
        notes
    ) VALUES (
        target_unit_key,
        CURRENT_TIMESTAMP,
        test_point,
        amd4_pcode,
        confidence,
        source_type_var,
        'Auto-generated position. Settlement: ' || settlement_name_var || 
        '. Attempts: ' || attempt_count || '/' || max_attempts ||
        '. Within FLOT: ' || point_within_flot
    );
    
    -- Update coordinates in russian_units table
    PERFORM update_unit_coordinates();
    
    -- Return results
    RETURN QUERY SELECT 
        target_unit_key,
        final_lat,
        final_lon,
        settlement_name_var,
        amd4_pcode,
        attempt_count,
        point_within_flot;
END;
$$;


--
-- Name: FUNCTION update_unit_location_by_pcode_flot(target_unit_key character varying, amd4_pcode character varying, dispersion_radius_m integer, max_attempts integer); Type: COMMENT; Schema: functions; Owner: -
--

COMMENT ON FUNCTION functions.update_unit_location_by_pcode_flot(target_unit_key character varying, amd4_pcode character varying, dispersion_radius_m integer, max_attempts integer) IS 'Updates a single unit location using PCODE and FLOT constraints. Generates dispersed position within settlement bounds and validates against FLOT.';


--
-- Name: validate_staging_data(); Type: FUNCTION; Schema: functions; Owner: -
--

CREATE FUNCTION functions.validate_staging_data() RETURNS TABLE(table_name character varying, total_records integer, valid_geometries integer, invalid_types integer, null_names integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'tactical_areas'::VARCHAR(50),
        COUNT(*)::INTEGER,
        COUNT(CASE WHEN ST_IsValid(geom) THEN 1 END)::INTEGER,
        COUNT(CASE WHEN type NOT IN ('frontal', 'rear', 'front') THEN 1 END)::INTEGER,
        COUNT(CASE WHEN tac_area_n IS NULL OR TRIM(tac_area_n) = '' THEN 1 END)::INTEGER
    FROM spatial_ref.tactical_areas_staging
    UNION ALL
    SELECT 
        'operational_areas'::VARCHAR(50),
        COUNT(*)::INTEGER,
        COUNT(CASE WHEN ST_IsValid(geom) THEN 1 END)::INTEGER,
        0::INTEGER,
        COUNT(CASE WHEN name IS NULL OR TRIM(name) = '' THEN 1 END)::INTEGER
    FROM spatial_ref.operational_areas_staging;
END;
$$;


--
-- PostgreSQL database dump complete
--

\unrestrict rW6Tct2gLJ5qsNsfhC2vTfSusr3UjxBHCRUfpv7ywE7HyJEhTlZ3Q7ZpTLejmMt

