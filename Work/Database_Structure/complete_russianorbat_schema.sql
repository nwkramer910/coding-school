-- Exported: 2025-11-13 21:21:13
-- Database: russianorbatukraine

--
-- PostgreSQL database dump
--

\restrict 1RkLnm5qmJqULLKJHWoHlmhIAvRZDqhzqdT8jXEuT0diTolHYsDMR2THsg5k2mn

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
-- Name: facilities; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA facilities;


--
-- Name: SCHEMA facilities; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA facilities IS 'Russian military facilities tracking tables';


--
-- Name: functions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA functions;


--
-- Name: geolocations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA geolocations;


--
-- Name: maid; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA maid;


--
-- Name: SCHEMA maid; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA maid IS '(MAID) tracking tables';


--
-- Name: orbat; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA orbat;


--
-- Name: SCHEMA orbat; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA orbat IS 'ORBAT analysis tables - units, positions, mentions';


--
-- Name: reference; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA reference;


--
-- Name: SCHEMA reference; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA reference IS 'Reference/lookup tables for MIL-STD-2525D codes and NATO standards';


--
-- Name: spatial_ref; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA spatial_ref;


--
-- Name: SCHEMA spatial_ref; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA spatial_ref IS 'Spatial reference datasets (boundaries, settlements, etc.)';


--
-- Name: pldbgapi; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pldbgapi WITH SCHEMA public;


--
-- Name: EXTENSION pldbgapi; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pldbgapi IS 'server-side support for debugging PL/pgSQL functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


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
-- Name: detect_redeployments(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.detect_redeployments() RETURNS TABLE(returned_unit_key character varying, returned_unit_name character varying, from_area character varying, to_area character varying, is_first_deployment boolean, redeployments_logged integer)
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
-- Name: FUNCTION detect_redeployments(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.detect_redeployments() IS 'Detects and logs redeployments for Brigade/Regiment/Division level units. Run manually after position updates.';


--
-- Name: find_facility_associated_maids(character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_facility_associated_maids(p_facility_key character varying, p_detection_radius_m integer DEFAULT 5000, p_minimum_detections integer DEFAULT 10, p_minimum_days integer DEFAULT 3) RETURNS TABLE(maid_id character varying, detection_count bigint, detection_days bigint, first_seen timestamp without time zone, last_seen timestamp without time zone, avg_quality double precision, suggested_confidence character varying)
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
        -- Suggest confidence level based on detection frequency and quality
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
-- Name: generate_unknown_unit_key(character); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_unknown_unit_key(p_category character) RETURNS character varying
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
-- Name: register_maid(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.register_maid(target_maid_id character varying, alias_name character varying, priority character varying DEFAULT 'MEDIUM'::character varying) RETURNS boolean
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
-- Name: update_unit_current_area(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_unit_current_area() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE russian_units ru
    SET current_operational_area_id = subq.latest_area
    FROM (
        SELECT DISTINCT ON (unit_key)
            unit_key,
            operational_area_id as latest_area
        FROM unit_positions
        WHERE operational_area_id IS NOT NULL
        ORDER BY unit_key, observation_date DESC
    ) subq
    WHERE ru.unit_key = subq.unit_key;
END;
$$;


--
-- Name: FUNCTION update_unit_current_area(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.update_unit_current_area() IS 'Syncs current_operational_area_id from unit_positions to russian_units';


--
-- Name: process_operational_areas_update(); Type: FUNCTION; Schema: spatial_ref; Owner: -
--

CREATE FUNCTION spatial_ref.process_operational_areas_update() RETURNS TABLE(action character varying, area_name character varying, details text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update existing areas with new geometries
    UPDATE spatial_ref.operational_areas oa
    SET 
        geometry = oas.geom,
        shape_length = oas.shape__len,  -- Note double underscore
        shape_area = oas.shape__are,     -- Note double underscore
        updated_at = CURRENT_TIMESTAMP
    FROM spatial_ref.operational_areas_staging oas
    WHERE oa.name = TRIM(oas.name)
        AND NOT ST_Equals(oa.geometry, oas.geom);
    
    -- Insert new areas
    INSERT INTO spatial_ref.operational_areas (
        name,
        geometry,
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
-- Name: process_operational_areas_upsert(); Type: FUNCTION; Schema: spatial_ref; Owner: -
--

CREATE FUNCTION spatial_ref.process_operational_areas_upsert() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_count integer;
    inserted_count integer;
    deactivated_count integer;
BEGIN
    -- Step 1: Set all existing operational areas to inactive
    UPDATE spatial_ref.operational_areas
    SET active = FALSE;
    
    GET DIAGNOSTICS deactivated_count = ROW_COUNT;
    
    -- Step 2: Update existing operational areas that match staging
    UPDATE spatial_ref.operational_areas oa
    SET 
        geom = oas.geom,
        shape_len = oas.shape__len,
        shape_are = oas.shape__are,
        active = TRUE
    FROM spatial_ref.operational_areas_staging oas
    WHERE oa.name = TRIM(oas.name)
        AND oas.name IS NOT NULL
        AND oas.geom IS NOT NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Step 3: Insert new operational areas from staging
    INSERT INTO spatial_ref.operational_areas 
        (name, geom, shape_len, shape_are, active)
    SELECT 
        TRIM(oas.name),
        oas.geom,
        oas.shape__len,
        oas.shape__are,
        TRUE
    FROM spatial_ref.operational_areas_staging oas
    WHERE oas.name IS NOT NULL
        AND oas.geom IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 
            FROM spatial_ref.operational_areas oa
            WHERE oa.name = TRIM(oas.name)
        );
    
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    -- Calculate how many remain inactive (were not updated back to TRUE)
    SELECT COUNT(*) INTO deactivated_count
    FROM spatial_ref.operational_areas
    WHERE active = FALSE;
    
    -- Raise notices with counts
    RAISE NOTICE 'Operational Areas - Updated: %, Inserted: %, Deactivated: %', 
        updated_count, inserted_count, deactivated_count;
END;
$$;


--
-- Name: process_tactical_areas_insert(); Type: FUNCTION; Schema: spatial_ref; Owner: -
--

CREATE FUNCTION spatial_ref.process_tactical_areas_insert() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    inserted_count integer;
BEGIN
    -- Insert from staging to tactical_areas
    INSERT INTO spatial_ref.tactical_areas 
        (tactical_area_name, area_type, geometry, shape_length, shape_area)
    SELECT 
        TRIM(tas.tac_area_n),
        tas.type,
        tas.geom,
        tas.shape_leng,
        tas.shape_area
    FROM spatial_ref.tactical_areas_staging tas
    WHERE tas.tac_area_n IS NOT NULL
        AND tas.type IS NOT NULL
        AND tas.geom IS NOT NULL
        AND tas.type IN ('frontal', 'rear');
    
    -- Get count of inserted rows
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    -- Raise notice with count
    RAISE NOTICE 'Inserted % rows into tactical_areas', inserted_count;
END;
$$;


--
-- Name: process_tactical_areas_update(); Type: FUNCTION; Schema: spatial_ref; Owner: -
--

CREATE FUNCTION spatial_ref.process_tactical_areas_update() RETURNS TABLE(action character varying, area_name character varying, area_type character varying, details text)
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
-- Name: process_tactical_areas_upsert(); Type: FUNCTION; Schema: spatial_ref; Owner: -
--

CREATE FUNCTION spatial_ref.process_tactical_areas_upsert() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    updated_count integer;
    inserted_count integer;
    deactivated_count integer;
BEGIN
    -- Step 1: Set all existing tactical areas to inactive
    UPDATE spatial_ref.tactical_areas
    SET active = FALSE;
    
    GET DIAGNOSTICS deactivated_count = ROW_COUNT;
    
    -- Step 2: Update existing tactical areas that match staging
    UPDATE spatial_ref.tactical_areas ta
    SET 
        geometry = tas.geom,
        shape_length = tas.shape_leng,
        shape_area = tas.shape_area,
        active = TRUE,
        updated_at = CURRENT_TIMESTAMP
    FROM spatial_ref.tactical_areas_staging tas
    WHERE ta.tactical_area_name = TRIM(tas.tac_area_n)
        AND ta.area_type = tas.type
        AND tas.tac_area_n IS NOT NULL
        AND tas.type IS NOT NULL
        AND tas.geom IS NOT NULL
        AND tas.type IN ('frontal', 'rear');
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Step 3: Insert new tactical areas from staging
    INSERT INTO spatial_ref.tactical_areas 
        (tactical_area_name, area_type, geometry, shape_length, shape_area, active)
    SELECT 
        TRIM(tas.tac_area_n),
        tas.type,
        tas.geom,
        tas.shape_leng,
        tas.shape_area,
        TRUE
    FROM spatial_ref.tactical_areas_staging tas
    WHERE tas.tac_area_n IS NOT NULL
        AND tas.type IS NOT NULL
        AND tas.geom IS NOT NULL
        AND tas.type IN ('frontal', 'rear')
        AND NOT EXISTS (
            SELECT 1 
            FROM spatial_ref.tactical_areas ta
            WHERE ta.tactical_area_name = TRIM(tas.tac_area_n)
                AND ta.area_type = tas.type
        );
    
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    
    -- Calculate how many remain inactive (were not updated back to TRUE)
    SELECT COUNT(*) INTO deactivated_count
    FROM spatial_ref.tactical_areas
    WHERE active = FALSE;
    
    -- Raise notices with counts
    RAISE NOTICE 'Tactical Areas - Updated: %, Inserted: %, Deactivated: %', 
        updated_count, inserted_count, deactivated_count;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: facility_orbat_associations; Type: TABLE; Schema: facilities; Owner: -
--

CREATE TABLE facilities.facility_orbat_associations (
    association_id integer NOT NULL,
    facility_key integer NOT NULL,
    unit_key character varying(10) NOT NULL,
    association_type character varying(30) NOT NULL,
    association_confidence character varying(20) NOT NULL,
    association_start_date timestamp without time zone NOT NULL,
    association_end_date timestamp without time zone,
    identification_method character varying(50),
    supporting_evidence text,
    estimated_personnel_count integer,
    analyst character varying(50) DEFAULT CURRENT_USER,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: facility_orbat_associations_association_id_seq; Type: SEQUENCE; Schema: facilities; Owner: -
--

CREATE SEQUENCE facilities.facility_orbat_associations_association_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facility_orbat_associations_association_id_seq; Type: SEQUENCE OWNED BY; Schema: facilities; Owner: -
--

ALTER SEQUENCE facilities.facility_orbat_associations_association_id_seq OWNED BY facilities.facility_orbat_associations.association_id;


--
-- Name: russian_facilities_facility_key_seq; Type: SEQUENCE; Schema: reference; Owner: -
--

CREATE SEQUENCE reference.russian_facilities_facility_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: russian_facilities; Type: TABLE; Schema: facilities; Owner: -
--

CREATE TABLE facilities.russian_facilities (
    facility_key integer DEFAULT nextval('reference.russian_facilities_facility_key_seq'::regclass) NOT NULL,
    facility_name character varying(200) NOT NULL,
    facility_name_ru character varying(200),
    facility_type character varying(50) NOT NULL,
    facility_subtype character varying(100),
    location public.geometry(Point,4326),
    location_lon double precision,
    location_lat double precision,
    military_district character varying(50),
    administrative_region character varying(100),
    nearest_settlement character varying(100),
    primary_function text,
    capacity_estimate integer,
    operational_status character varying(30) DEFAULT 'ACTIVE'::character varying,
    strategic_importance character varying(20),
    identification_confidence character varying(20) DEFAULT 'Medium'::character varying,
    last_activity_observed timestamp without time zone,
    alternate_names text[],
    military_unit_number character varying(50),
    creator text DEFAULT CURRENT_USER,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_editor text DEFAULT CURRENT_USER,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    analyst_notes text,
    sources character varying(500)
);


--
-- Name: maid_orbat_associations; Type: TABLE; Schema: maid; Owner: -
--

CREATE TABLE maid.maid_orbat_associations (
    association_id integer NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_alias character varying(50) NOT NULL,
    associated_unit_key character varying(10) NOT NULL,
    association_confidence character varying(20) NOT NULL,
    association_method character varying(30),
    association_date_start timestamp without time zone NOT NULL,
    association_date_end timestamp without time zone,
    supporting_evidence text,
    analyst character varying(50),
    validated boolean DEFAULT false,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: maid_orbat_associations_association_id_seq; Type: SEQUENCE; Schema: maid; Owner: -
--

CREATE SEQUENCE maid.maid_orbat_associations_association_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maid_orbat_associations_association_id_seq; Type: SEQUENCE OWNED BY; Schema: maid; Owner: -
--

ALTER SEQUENCE maid.maid_orbat_associations_association_id_seq OWNED BY maid.maid_orbat_associations.association_id;


--
-- Name: maid_positions; Type: TABLE; Schema: maid; Owner: -
--

CREATE TABLE maid.maid_positions (
    maid_observation_id bigint NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
)
PARTITION BY HASH (maid_id);


--
-- Name: TABLE maid_positions; Type: COMMENT; Schema: maid; Owner: -
--

COMMENT ON TABLE maid.maid_positions IS 'Primary MAID tracking table with quality assessment flags and ORBAT integration';


--
-- Name: COLUMN maid_positions.maid_id; Type: COMMENT; Schema: maid; Owner: -
--

COMMENT ON COLUMN maid.maid_positions.maid_id IS 'Mobile Advertising ID (UUID format)';


--
-- Name: COLUMN maid_positions.maid_type; Type: COMMENT; Schema: maid; Owner: -
--

COMMENT ON COLUMN maid.maid_positions.maid_type IS 'AFID (Android) or IDFA (iOS)';


--
-- Name: COLUMN maid_positions.location_quality; Type: COMMENT; Schema: maid; Owner: -
--

COMMENT ON COLUMN maid.maid_positions.location_quality IS 'AUTO-UPDATED: Overall location data quality assessment';


--
-- Name: COLUMN maid_positions.accuracy_class; Type: COMMENT; Schema: maid; Owner: -
--

COMMENT ON COLUMN maid.maid_positions.accuracy_class IS 'AUTO-UPDATED: Tactical (<50m), Operational (<500m), Strategic (>500m)';


--
-- Name: maid_positions_maid_observation_id_seq; Type: SEQUENCE; Schema: maid; Owner: -
--

CREATE SEQUENCE maid.maid_positions_maid_observation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maid_positions_maid_observation_id_seq; Type: SEQUENCE OWNED BY; Schema: maid; Owner: -
--

ALTER SEQUENCE maid.maid_positions_maid_observation_id_seq OWNED BY maid.maid_positions.maid_observation_id;


--
-- Name: maid_registry; Type: TABLE; Schema: maid; Owner: -
--

CREATE TABLE maid.maid_registry (
    maid_id character varying(36) NOT NULL,
    maid_alias character varying(50) NOT NULL,
    first_observed timestamp without time zone,
    last_observed timestamp without time zone,
    primary_device_type character varying(10),
    total_observations bigint DEFAULT 0,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    priority_level character varying(15) DEFAULT 'MEDIUM'::character varying,
    analyst_notes text,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: redeployment_events; Type: TABLE; Schema: orbat; Owner: -
--

CREATE TABLE orbat.redeployment_events (
    event_id integer NOT NULL,
    unit_key character varying(10) NOT NULL,
    unit_name character varying(100),
    from_area_id integer,
    to_area_id integer NOT NULL,
    from_observation_id integer,
    to_observation_id integer NOT NULL,
    redeployment_date timestamp without time zone NOT NULL,
    days_between integer,
    is_first_deployment boolean DEFAULT false,
    detected_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    notes text
);


--
-- Name: TABLE redeployment_events; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON TABLE orbat.redeployment_events IS 'Logs all detected redeployments for Brigade/Regiment/Division level units';


--
-- Name: redeployment_events_event_id_seq; Type: SEQUENCE; Schema: orbat; Owner: -
--

CREATE SEQUENCE orbat.redeployment_events_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: redeployment_events_event_id_seq; Type: SEQUENCE OWNED BY; Schema: orbat; Owner: -
--

ALTER SEQUENCE orbat.redeployment_events_event_id_seq OWNED BY orbat.redeployment_events.event_id;


--
-- Name: russian_units; Type: TABLE; Schema: orbat; Owner: -
--

CREATE TABLE orbat.russian_units (
    unit_key character varying(10) NOT NULL,
    mun_number character varying(20),
    unit_name character varying(100),
    unit_type character varying(50),
    parent_unit character varying(100),
    identity_ integer,
    context integer,
    symbolset integer,
    symbolentity integer,
    modifier1 integer,
    modifier2 integer,
    specialentitysubtype integer,
    echelon integer,
    status integer,
    hq_indicator integer,
    uniquedesignation character varying(20),
    higherformation character varying(20),
    reinforced character varying(10),
    operational_condition character varying(10),
    specialheadquarters integer,
    echelonlabel character varying(10),
    direction integer,
    speedunit integer,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    staffcomments character varying(100),
    credibility integer,
    reliability text,
    countrycode character varying(50),
    countrylabel character varying(50),
    basinglocation character varying(100),
    baselatitude double precision,
    baselongitude double precision,
    creator text,
    editor text,
    russianunitnumber character varying(10),
    last_observed timestamp without time zone,
    current_lat double precision,
    current_long double precision,
    home_facility_key integer,
    current_facility_key integer,
    facility_assignment_type character varying(30),
    facility_assignment_date timestamp without time zone,
    facility_assignment_confidence character varying(20),
    current_action character varying(50),
    military_district character varying(30),
    current_operational_area_id integer,
    shape public.geometry(Point,4326),
    current_tactical_area_id integer,
    parent_unit_key character varying(10),
    opcon_unit_key character varying(10),
    adcon_unit_key character varying(10),
    military_district_key character varying(10),
    grouping_of_forces_key character varying(10),
    combined_arms_army_key character varying(10),
    parent_unit_legacy character varying(100),
    CONSTRAINT valid_facility_assignment_type CHECK (((facility_assignment_type IS NULL) OR ((facility_assignment_type)::text = ANY (ARRAY[('HOME_BASE'::character varying)::text, ('DEPLOYED_TO'::character varying)::text, ('TRAINING_AT'::character varying)::text, ('IN_TRANSIT'::character varying)::text, ('UNKNOWN'::character varying)::text]))))
);


--
-- Name: COLUMN russian_units.home_facility_key; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.russian_units.home_facility_key IS 'Permanent/primary base facility for this unit';


--
-- Name: COLUMN russian_units.current_facility_key; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.russian_units.current_facility_key IS 'Current facility assignment (may differ from home base)';


--
-- Name: COLUMN russian_units.facility_assignment_type; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.russian_units.facility_assignment_type IS 'Type of current facility assignment';


--
-- Name: COLUMN russian_units.current_action; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.russian_units.current_action IS 'Most recent action/activity from unit_positions (auto-updated)';


--
-- Name: tactical_relocation_events; Type: TABLE; Schema: orbat; Owner: -
--

CREATE TABLE orbat.tactical_relocation_events (
    relocation_id integer NOT NULL,
    unit_key character varying(10) NOT NULL,
    unit_name character varying(100),
    from_tactical_area_id integer,
    to_tactical_area_id integer,
    from_area_type character varying(50),
    to_area_type character varying(50),
    operational_area_id integer,
    from_observation_id integer,
    to_observation_id integer,
    relocation_date timestamp without time zone,
    days_between integer,
    movement_type character varying(50),
    detected_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tactical_relocation_events_movement_type_check CHECK (((movement_type)::text = ANY ((ARRAY['front_to_rear'::character varying, 'rear_to_front'::character varying, 'lateral'::character varying, 'initial_tactical'::character varying])::text[])))
);


--
-- Name: tactical_relocation_events_relocation_id_seq; Type: SEQUENCE; Schema: orbat; Owner: -
--

CREATE SEQUENCE orbat.tactical_relocation_events_relocation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tactical_relocation_events_relocation_id_seq; Type: SEQUENCE OWNED BY; Schema: orbat; Owner: -
--

ALTER SEQUENCE orbat.tactical_relocation_events_relocation_id_seq OWNED BY orbat.tactical_relocation_events.relocation_id;


--
-- Name: unit_mentions; Type: TABLE; Schema: orbat; Owner: -
--

CREATE TABLE orbat.unit_mentions (
    mention_id integer NOT NULL,
    unit_key character varying(10),
    unknown_unit_key character varying(10),
    source_id integer,
    observation_date timestamp without time zone NOT NULL,
    tactical_area_id integer,
    operational_area_id integer,
    adm4_pcode character varying(20),
    location public.geometry(Point,4326),
    location_precision character varying(20),
    operational_condition character varying(10),
    status integer,
    reinforced character varying(10),
    action text,
    new_parent_unit_key character varying(10),
    new_opcon_unit_key character varying(10),
    new_adcon_unit_key character varying(10),
    command_change_date date,
    is_detached_element boolean DEFAULT false,
    is_main_body boolean DEFAULT false,
    element_size_estimate character varying(50),
    element_description text,
    detachment_timeframe_start date,
    detachment_timeframe_end date,
    credibility integer,
    reliability text,
    confidence_level character varying(20) DEFAULT 'Medium'::character varying,
    review_status character varying(20) DEFAULT 'pending'::character varying,
    reviewed_by character varying(50),
    reviewed_date timestamp without time zone,
    analyst character varying(50) NOT NULL,
    analyst_notes text,
    priority integer DEFAULT 3,
    source_url text,
    source_excerpt text,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    committed_date timestamp without time zone,
    committed_to_position_id integer,
    CONSTRAINT check_unit_reference CHECK (((unit_key IS NOT NULL) OR (unknown_unit_key IS NOT NULL)))
);


--
-- Name: COLUMN unit_mentions.unknown_unit_key; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_mentions.unknown_unit_key IS 'Links to unknown_units table (za/zb keys). Used for operationally significant elements without confirmed ORBAT entries.';


--
-- Name: COLUMN unit_mentions.is_detached_element; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_mentions.is_detached_element IS 'Analyst-marked: TRUE if this mention represents a detached element, enabling multiple simultaneous positions for same unit. Unit will display with reinforced="-" (reduced strength).';


--
-- Name: COLUMN unit_mentions.is_main_body; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_mentions.is_main_body IS 'Analyst-marked: TRUE if this mention represents the main body position (not detached element). Used to prioritize which position updates russian_units.current_lat/long.';


--
-- Name: COLUMN unit_mentions.detachment_timeframe_start; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_mentions.detachment_timeframe_start IS 'When this detachment began (analyst judgment, ~30 day window typical). Used to determine if multiple positions are truly simultaneous.';


--
-- Name: unit_mentions_mention_id_seq; Type: SEQUENCE; Schema: orbat; Owner: -
--

CREATE SEQUENCE orbat.unit_mentions_mention_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unit_mentions_mention_id_seq; Type: SEQUENCE OWNED BY; Schema: orbat; Owner: -
--

ALTER SEQUENCE orbat.unit_mentions_mention_id_seq OWNED BY orbat.unit_mentions.mention_id;


--
-- Name: unit_positions; Type: TABLE; Schema: orbat; Owner: -
--

CREATE TABLE orbat.unit_positions (
    observation_id integer NOT NULL,
    unit_key character varying(10),
    observation_date timestamp without time zone NOT NULL,
    location public.geometry(Point,4326),
    confidence_level character varying(20) DEFAULT 'Medium'::character varying,
    source_type character varying(50),
    notes text,
    action character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sep022025_lat double precision,
    sep022025_long double precision,
    adm4_pcode character varying(20),
    analyst text,
    operational_area character varying(100),
    status integer,
    reinforced character varying(5),
    credibility integer,
    reliability text,
    operational_condition character varying(20),
    operational_area_id integer,
    tactical_area_id integer,
    source_id integer,
    source_utl text,
    CONSTRAINT check_status_valid CHECK (((status IS NULL) OR (status = ANY (ARRAY[0, 1, 2, 3, 4, 5]))))
);


--
-- Name: COLUMN unit_positions.status; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_positions.status IS 'MIL-STD-2525D Status codes:
0 = Present
1 = Planned/Anticipated/Suspect
2 = Present/Fully capable
3 = Present/Damaged
4 = Present/Destroyed
5 = Present/Full to capacity';


--
-- Name: COLUMN unit_positions.reinforced; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_positions.reinforced IS 'Reinforcement status: +, -, ±, NULL (analyst assessment)';


--
-- Name: COLUMN unit_positions.credibility; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_positions.credibility IS 'Source Credibility (NATO STANAG):
1 = Reliable (A)
2 = Usually Reliable (B) 
3 = Fairly Reliable (C)
4 = Not Usually Reliable (D)
5 = Unreliable (E)
6 = Reliability Cannot Be Judged (F)';


--
-- Name: COLUMN unit_positions.reliability; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unit_positions.reliability IS 'Information Reliability (NATO STANAG):
1 = Confirmed by other sources (1)
2 = Probably True (2)
3 = Possibly True (3)
4 = Doubtful (4)
5 = Improbable (5)
6 = Truth Cannot Be Judged (6)';


--
-- Name: unit_positions_observation_id_seq; Type: SEQUENCE; Schema: orbat; Owner: -
--

CREATE SEQUENCE orbat.unit_positions_observation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unit_positions_observation_id_seq; Type: SEQUENCE OWNED BY; Schema: orbat; Owner: -
--

ALTER SEQUENCE orbat.unit_positions_observation_id_seq OWNED BY orbat.unit_positions.observation_id;


--
-- Name: unknown_units; Type: TABLE; Schema: orbat; Owner: -
--

CREATE TABLE orbat.unknown_units (
    unknown_unit_key character varying(10) NOT NULL,
    provisional_name character varying(200) NOT NULL,
    unknown_category character(1) NOT NULL,
    element_type character varying(50),
    parent_unit_key character varying(10),
    parent_unit_name character varying(100),
    estimated_echelon integer,
    identity_ integer,
    context integer,
    symbolset integer,
    symbolentity integer,
    modifier1 integer,
    modifier2 integer,
    specialentitysubtype integer,
    echelon integer,
    hq_indicator integer,
    uniquedesignation character varying(20) DEFAULT 'UNK'::character varying,
    higherformation character varying(20),
    current_lat double precision,
    current_long double precision,
    last_observed timestamp without time zone,
    operational_area_id integer,
    tactical_area_id integer,
    operational_condition character varying(10),
    status integer,
    reinforced character varying(10),
    credibility integer,
    reliability text,
    current_action character varying(50),
    first_mentioned timestamp without time zone NOT NULL,
    last_mentioned timestamp without time zone,
    mention_count integer DEFAULT 0,
    promoted_to_unit_key character varying(10),
    promoted_date timestamp without time zone,
    promotion_reason text,
    discovered_by character varying(50),
    analyst_notes text,
    tracking_priority integer DEFAULT 3,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unknown_units_unknown_category_check CHECK ((unknown_category = ANY (ARRAY['a'::bpchar, 'b'::bpchar])))
);


--
-- Name: TABLE unknown_units; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON TABLE orbat.unknown_units IS 'Tracks operationally significant elements without confirmed ORBAT entries. Keys: za##### for subordinate elements, zb##### for assets. Can remain unknown indefinitely or be promoted to russian_units when confirmed.';


--
-- Name: COLUMN unknown_units.unknown_category; Type: COMMENT; Schema: orbat; Owner: -
--

COMMENT ON COLUMN orbat.unknown_units.unknown_category IS 'a=subordinate echelon (drone company, assault element), b=asset (TOS-A1, arty battery)';


--
-- Name: echelon_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.echelon_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    symbol_display character varying(20),
    nato_size character varying(30),
    hierarchy_level integer
);


--
-- Name: TABLE echelon_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.echelon_codes IS 'NATO MIL-STD-2525D echelon amplifier codes. Used to indicate the hierarchical level of military units.';


--
-- Name: COLUMN echelon_codes.symbol_display; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.echelon_codes.symbol_display IS 'Visual representation of echelon (e.g., I, II, III, X, XX, XXX)';


--
-- Name: COLUMN echelon_codes.hierarchy_level; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.echelon_codes.hierarchy_level IS 'Numerical ordering for sorting echelons from smallest (1) to largest (14)';


--
-- Name: symbology_entity_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.symbology_entity_codes (
    code integer NOT NULL,
    entity_name character varying(100),
    entity_type_name character varying(100),
    entity_subtype_name character varying(100),
    display_name character varying(300) NOT NULL,
    hierarchy_level integer NOT NULL,
    usage_notes text,
    CONSTRAINT symbology_entity_codes_hierarchy_level_check CHECK (((hierarchy_level >= 1) AND (hierarchy_level <= 3)))
);


--
-- Name: TABLE symbology_entity_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.symbology_entity_codes IS 'MIL-STD-2525D Land Unit entity codes for NATO symbology. Organized hierarchically: Entity (xx0000) > Entity Type (xxyy00) > Entity Subtype (xxyyzz). Use display_name for user-friendly dropdowns.';


--
-- Name: COLUMN symbology_entity_codes.code; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.symbology_entity_codes.code IS '6-digit MIL-STD-2525D entity code. Maps to symbolentity field in russian_units table.';


--
-- Name: COLUMN symbology_entity_codes.display_name; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.symbology_entity_codes.display_name IS 'Hierarchical display format for dropdowns: "Entity : Type : Subtype"';


--
-- Name: COLUMN symbology_entity_codes.hierarchy_level; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.symbology_entity_codes.hierarchy_level IS '1 = Entity only, 2 = Entity + Type, 3 = Entity + Type + Subtype';


--
-- Name: current_orbat_assessment; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.current_orbat_assessment AS
 SELECT up.unit_key,
    ru.unit_name,
    ru.mun_number,
    ru.unit_type,
    up.location,
    up.observation_date,
    up.confidence_level,
    up.source_type,
    ru.current_lat,
    ru.current_long,
    public.st_setsrid(public.st_makepoint(ru.current_long, ru.current_lat), 4326) AS shape,
    ru.credibility,
    ru.reliability,
    ru.current_action,
    ru.operational_condition AS actual_operational_condition,
    ru.status AS actual_status,
    ru.reinforced AS actual_reinforced,
    ru.identity_,
    ru.context,
    ru.symbolset,
    ru.symbolentity,
    ru.modifier1,
    ru.modifier2,
    ru.specialentitysubtype,
    ru.echelon,
    ru.hq_indicator,
    ru.uniquedesignation,
    ru.higherformation,
    ru.specialheadquarters,
    ru.echelonlabel,
    sec.display_name AS entity_name,
    (((ec.symbol_display)::text || ' - '::text) || (ec.description)::text) AS echelon_name,
    1 AS status,
    '-'::text AS reinforced
   FROM (((orbat.unit_positions up
     JOIN orbat.russian_units ru ON (((up.unit_key)::text = (ru.unit_key)::text)))
     LEFT JOIN reference.symbology_entity_codes sec ON ((ru.symbolentity = sec.code)))
     LEFT JOIN reference.echelon_codes ec ON ((ru.echelon = ec.code)))
  WHERE (up.observation_id IN ( SELECT DISTINCT ON (unit_positions.unit_key) unit_positions.observation_id
           FROM orbat.unit_positions
          ORDER BY unit_positions.unit_key, unit_positions.observation_date DESC))
  ORDER BY ru.unit_name;


--
-- Name: maid_positions_p01; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p01 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p02; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p02 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p03 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p04 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p05; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p05 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p06; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p06 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p07; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p07 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p08; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p08 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p09; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p09 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p10 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p11; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p11 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p12; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p12 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p13; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p13 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p14; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p14 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p15; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p15 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: maid_positions_p16; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.maid_positions_p16 (
    maid_observation_id bigint DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass) NOT NULL,
    maid_id character varying(36) NOT NULL,
    maid_type character varying(10),
    user_locale character varying(5),
    device_make character varying(20),
    device_model character varying(50),
    device_os character varying(20),
    device_os_version character varying(20),
    latitude double precision,
    longitude double precision,
    location public.geometry(Point,4326),
    "timestamp" timestamp without time zone,
    ip_address inet,
    horizontal_accuracy double precision,
    speed double precision,
    heading integer,
    course integer,
    operator_name character varying(50),
    cell_identity character varying(50),
    connection_method character varying(20),
    gateway_latitude double precision,
    gateway_longitude double precision,
    derived_country character varying(10),
    poly integer,
    duplicates integer,
    location_quality character varying(20) DEFAULT 'UNASSESSED'::character varying,
    geographic_anomaly boolean DEFAULT false,
    accuracy_class character varying(15) DEFAULT 'UNASSESSED'::character varying,
    probable_jamming boolean DEFAULT false,
    probable_vpn boolean DEFAULT false,
    movement_plausible boolean DEFAULT true,
    operational_relevance character varying(20),
    overall_confidence double precision,
    quality_notes text,
    import_batch_id character varying(50),
    analyst character varying(50),
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_quality_check timestamp without time zone
);


--
-- Name: sources; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.sources (
    source_id integer NOT NULL,
    source_name character varying(200) NOT NULL,
    channel_link text,
    source_origin character varying(5) NOT NULL,
    source_credibility integer,
    source_reliability text,
    status character varying(20) DEFAULT 'active'::character varying,
    analyst_notes text,
    created_by character varying(50) NOT NULL,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    self boolean
);


--
-- Name: TABLE sources; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.sources IS 'Registry of OSINT sources with baseline credibility/reliability ratings. Provides analyst guidance during mention review and commitment workflow.';


--
-- Name: COLUMN sources.source_credibility; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.sources.source_credibility IS 'Default credibility rating for this source. Analyst can override per-mention during review.';


--
-- Name: COLUMN sources.source_reliability; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.sources.source_reliability IS 'Default reliability rating for this source. Analyst can override per-mention during review.';


--
-- Name: COLUMN sources.analyst_notes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.sources.analyst_notes IS 'Operational context about source behavior, biases, geographic focus, or other considerations for analysts.';


--
-- Name: tactical_areas; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.tactical_areas (
    tactical_area_id integer NOT NULL,
    tactical_area_name character varying(255) NOT NULL,
    area_type character varying(50) NOT NULL,
    geometry public.geometry(MultiPolygon,4326) NOT NULL,
    shape_length numeric,
    shape_area numeric,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    active boolean,
    CONSTRAINT tactical_areas_area_type_check CHECK (((area_type)::text = ANY ((ARRAY['frontal'::character varying, 'rear'::character varying])::text[])))
);


--
-- Name: mentions_by_unit_daily; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.mentions_by_unit_daily AS
 SELECT COALESCE(um.unit_key, um.unknown_unit_key) AS unit_identifier,
    COALESCE(ru.unit_name, uu.provisional_name) AS unit_name,
    date_trunc('day'::text, um.observation_date) AS day,
    count(*) AS mention_count,
    count(*) FILTER (WHERE um.is_detached_element) AS detached_element_mentions,
    count(*) FILTER (WHERE (s.self = true)) AS self_reported_count,
    array_agg(DISTINCT ta.tactical_area_name) AS mentioned_areas,
    array_agg(DISTINCT s.source_name) AS sources,
    array_agg(DISTINCT s.source_origin) AS source_origins,
    min(um.observation_date) AS earliest_mention,
    max(um.observation_date) AS latest_mention
   FROM ((((orbat.unit_mentions um
     LEFT JOIN orbat.russian_units ru ON (((um.unit_key)::text = (ru.unit_key)::text)))
     LEFT JOIN orbat.unknown_units uu ON (((um.unknown_unit_key)::text = (uu.unknown_unit_key)::text)))
     LEFT JOIN spatial_ref.tactical_areas ta ON ((um.tactical_area_id = ta.tactical_area_id)))
     LEFT JOIN reference.sources s ON ((um.source_id = s.source_id)))
  WHERE (((um.review_status)::text = 'pending'::text) AND (um.observation_date >= (CURRENT_DATE - '7 days'::interval)))
  GROUP BY COALESCE(um.unit_key, um.unknown_unit_key), COALESCE(ru.unit_name, uu.provisional_name), (date_trunc('day'::text, um.observation_date))
  ORDER BY (date_trunc('day'::text, um.observation_date)) DESC, (count(*)) DESC;


--
-- Name: VIEW mentions_by_unit_daily; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.mentions_by_unit_daily IS 'Batch review helper: shows units with multiple mentions per day. Self_reported_count shows how many came from the unit itself (high location confidence).';


--
-- Name: pending_mentions_recent; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.pending_mentions_recent AS
 SELECT um.mention_id,
    COALESCE(um.unit_key, um.unknown_unit_key) AS unit_identifier,
    COALESCE(ru.unit_name, uu.provisional_name) AS unit_name,
    um.observation_date,
    ta.tactical_area_name AS tactical_area,
    s.source_name,
    s.self AS self_reported,
    s.source_origin,
    s.source_credibility,
    s.source_reliability,
        CASE
            WHEN (um.location IS NOT NULL) THEN 'Exact coordinates'::text
            WHEN (um.adm4_pcode IS NOT NULL) THEN 'Settlement-level'::text
            WHEN (um.tactical_area_id IS NOT NULL) THEN 'Tactical area'::text
            ELSE 'Direction only'::text
        END AS location_precision,
    um.is_detached_element,
    um.is_main_body,
    um.element_description,
    um.priority,
    um.analyst,
    um.analyst_notes,
    um.source_url,
    ( SELECT count(*) AS count
           FROM orbat.unit_mentions um2
          WHERE (((COALESCE(um2.unit_key, um2.unknown_unit_key))::text = (COALESCE(um.unit_key, um.unknown_unit_key))::text) AND ((um2.review_status)::text = 'approved'::text) AND ((um2.observation_date)::date = (um.observation_date)::date) AND (um2.tactical_area_id <> um.tactical_area_id))) AS conflicting_mentions
   FROM ((((orbat.unit_mentions um
     LEFT JOIN orbat.russian_units ru ON (((um.unit_key)::text = (ru.unit_key)::text)))
     LEFT JOIN orbat.unknown_units uu ON (((um.unknown_unit_key)::text = (uu.unknown_unit_key)::text)))
     LEFT JOIN reference.sources s ON ((um.source_id = s.source_id)))
     LEFT JOIN spatial_ref.tactical_areas ta ON ((um.tactical_area_id = ta.tactical_area_id)))
  WHERE ((um.review_status)::text = 'pending'::text)
  ORDER BY um.observation_date DESC, um.priority;


--
-- Name: VIEW pending_mentions_recent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.pending_mentions_recent IS 'Pending mentions from last 24 hours with source context. Self-reported (self=TRUE) = high location confidence. Use source_origin and credibility for analyst judgment.';


--
-- Name: potential_split_units; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.potential_split_units AS
 SELECT COALESCE(um.unit_key, um.unknown_unit_key) AS unit_identifier,
    COALESCE(ru.unit_name, uu.provisional_name) AS unit_name,
    count(DISTINCT um.tactical_area_id) AS area_count,
    array_agg(DISTINCT ta.tactical_area_name ORDER BY ta.tactical_area_name) AS areas_mentioned,
    count(*) AS total_mentions,
    count(*) FILTER (WHERE (s.self = true)) AS self_reported_mentions,
    min(um.observation_date) AS earliest,
    max(um.observation_date) AS latest,
    (EXTRACT(epoch FROM (max(um.observation_date) - min(um.observation_date))) / (86400)::numeric) AS days_span
   FROM ((((orbat.unit_mentions um
     LEFT JOIN orbat.russian_units ru ON (((um.unit_key)::text = (ru.unit_key)::text)))
     LEFT JOIN orbat.unknown_units uu ON (((um.unknown_unit_key)::text = (uu.unknown_unit_key)::text)))
     LEFT JOIN spatial_ref.tactical_areas ta ON ((um.tactical_area_id = ta.tactical_area_id)))
     LEFT JOIN reference.sources s ON ((um.source_id = s.source_id)))
  WHERE (((um.review_status)::text = 'pending'::text) AND (um.observation_date >= (CURRENT_DATE - '30 days'::interval)))
  GROUP BY COALESCE(um.unit_key, um.unknown_unit_key), COALESCE(ru.unit_name, uu.provisional_name)
 HAVING (count(DISTINCT um.tactical_area_id) >= 2)
  ORDER BY (count(DISTINCT um.tactical_area_id)) DESC, (count(*) FILTER (WHERE (s.self = true))) DESC;


--
-- Name: VIEW potential_split_units; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.potential_split_units IS 'Flags units with mentions in multiple tactical areas within 30 days. High self_reported_mentions = likely legitimate detached elements. Low = potential data conflicts. Analyst reviews to determine.';


--
-- Name: operational_areas; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.operational_areas (
    gid integer NOT NULL,
    name character varying(254),
    shape_len numeric,
    shape_are numeric,
    area_id integer NOT NULL,
    geom public.geometry(MultiPolygon,4326),
    active boolean
);


--
-- Name: redeployment_history; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.redeployment_history AS
 SELECT re.event_id,
    re.unit_key,
    re.unit_name,
    oa_from.name AS from_area,
    oa_to.name AS to_area,
    re.redeployment_date,
    re.days_between,
    re.is_first_deployment,
    re.notes
   FROM ((orbat.redeployment_events re
     LEFT JOIN spatial_ref.operational_areas oa_from ON ((re.from_area_id = oa_from.area_id)))
     JOIN spatial_ref.operational_areas oa_to ON ((re.to_area_id = oa_to.area_id)))
  ORDER BY re.redeployment_date DESC;


--
-- Name: VIEW redeployment_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.redeployment_history IS 'Complete history of all detected unit redeployments with area names';


--
-- Name: credibility_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.credibility_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    letter_code character(1) NOT NULL,
    explanation character varying(200)
);


--
-- Name: TABLE credibility_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.credibility_codes IS 'NATO STANAG source credibility assessment scale (A-F rating system)';


--
-- Name: operational_condition_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.operational_condition_codes (
    code character varying(10) NOT NULL,
    description character varying(50) NOT NULL,
    symbol_display character varying(100),
    personnel_range character varying(50),
    numeric_value integer
);


--
-- Name: TABLE operational_condition_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.operational_condition_codes IS 'Operational condition codes. Based on MIL-STD-2525D Appendix D, Table D-II, Field AL';


--
-- Name: reinforcement_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.reinforcement_codes (
    code character varying(10) NOT NULL,
    description character varying(50) NOT NULL,
    explanation character varying(200)
);


--
-- Name: TABLE reinforcement_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.reinforcement_codes IS 'MIL-STD-2525D reinforcement status text amplifier values (Field F)';


--
-- Name: reliability_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.reliability_codes (
    code text NOT NULL,
    description character varying(50) NOT NULL,
    display_code character varying(5) NOT NULL,
    explanation character varying(200),
    numeric_value integer
);


--
-- Name: TABLE reliability_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.reliability_codes IS 'Reliability assessment scale - accepts both NATO number codes (1-6) and letter codes (A-F)';


--
-- Name: status_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.status_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    symbol_use character varying(100)
);


--
-- Name: TABLE status_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.status_codes IS 'MIL-STD-2525D Status field values (Digit 7, Table A-IV)';


--
-- Name: all_codes_reference; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.all_codes_reference AS
 SELECT 'STATUS'::text AS code_type,
    (status_codes.code)::text AS code_value,
    status_codes.description,
    status_codes.symbol_use AS additional_info,
    1 AS sort_order
   FROM reference.status_codes
UNION ALL
 SELECT 'ECHELON'::text AS code_type,
    (echelon_codes.code)::text AS code_value,
    echelon_codes.description,
    ((((echelon_codes.symbol_display)::text || ' (NATO Size: '::text) || (echelon_codes.nato_size)::text) || ')'::text) AS additional_info,
    2 AS sort_order
   FROM reference.echelon_codes
UNION ALL
 SELECT 'OPERATIONAL_CONDITION'::text AS code_type,
    operational_condition_codes.code AS code_value,
    operational_condition_codes.description,
    ('Personnel: '::text || (operational_condition_codes.personnel_range)::text) AS additional_info,
    3 AS sort_order
   FROM reference.operational_condition_codes
UNION ALL
 SELECT 'CREDIBILITY'::text AS code_type,
    (credibility_codes.code)::text AS code_value,
    credibility_codes.description,
    ((('Letter Code: '::text || (credibility_codes.letter_code)::text) || ' - '::text) || (credibility_codes.explanation)::text) AS additional_info,
    4 AS sort_order
   FROM reference.credibility_codes
UNION ALL
 SELECT 'RELIABILITY'::text AS code_type,
    reliability_codes.code AS code_value,
    reliability_codes.description,
    ((((('Display: '::text || (reliability_codes.display_code)::text) || ' (Numeric: '::text) || (reliability_codes.numeric_value)::text) || ') - '::text) || (reliability_codes.explanation)::text) AS additional_info,
    5 AS sort_order
   FROM reference.reliability_codes
UNION ALL
 SELECT 'REINFORCEMENT'::text AS code_type,
    reinforcement_codes.code AS code_value,
    reinforcement_codes.description,
    reinforcement_codes.explanation AS additional_info,
    6 AS sort_order
   FROM reference.reinforcement_codes
  ORDER BY 5, 2;


--
-- Name: analyst_reference_codes; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.analyst_reference_codes AS
 SELECT 'status'::text AS category,
    (status_codes.code)::text AS code,
    status_codes.description,
    NULL::text AS notes,
    1 AS sort_order
   FROM ( VALUES (0,'Confirmed Present - Unit currently in the area'::text), (1,'Probably Present - High confidence unit is in the area'::text), (2,'Possibly Present - Moderate confidence'::text), (3,'Presence Doubtful - Low confidence'::text), (4,'Probably Not Present - High confidence unit is NOT in area'::text), (5,'Confirmed Absent - Unit definitively not in the area'::text)) status_codes(code, description)
UNION ALL
 SELECT 'reinforced'::text AS category,
    reinforced_codes.modifier AS code,
    reinforced_codes.description,
    reinforced_codes.usage_notes AS notes,
    2 AS sort_order
   FROM ( VALUES ('+'::text,'Reinforced - Unit augmented with additional elements'::text,'Use for units operating above authorized strength'::text), ('-'::text,'Reduced/Detached - Unit operating with fewer elements'::text,'REQUIRED for detached elements. Also used for degraded units'::text), ('±'::text,'Reinforced and Reduced - Mixed augmentation'::text,'Rare - unit has both attachments and detachments'::text), ('+/-'::text,'Task Organized - Significantly reorganized'::text,'Unit structure significantly different from TOE'::text), (NULL::text,'Normal strength - No modifier'::text,'Default - unit at or near authorized strength'::text)) reinforced_codes(modifier, description, usage_notes)
UNION ALL
 SELECT 'operational_condition'::text AS category,
    condition_codes.condition_code AS code,
    condition_codes.description,
    condition_codes.notes,
    3 AS sort_order
   FROM ( VALUES ('100'::text,'Fully Capable'::text,'All equipment operational, full manning'::text), ('110'::text,'Substantially Capable'::text,'Minor equipment/personnel shortfalls'::text), ('120'::text,'Marginally Capable'::text,'Moderate degradation but mission-capable'::text), ('200'::text,'Damaged - Mission Capable'::text,'Damaged but can still perform mission'::text), ('210'::text,'Damaged - Marginally Capable'::text,'Significant damage, reduced capability'::text), ('220'::text,'Damaged - Not Mission Capable'::text,'Too damaged to perform primary mission'::text), ('300'::text,'Destroyed'::text,'Unit combat ineffective, requires reconstitution'::text), ('400'::text,'Full to Capacity'::text,'Operating at maximum capacity'::text), ('410'::text,'Substantially Full'::text,'Near capacity'::text), ('420'::text,'Moderately Full'::text,'Moderate utilization'::text), ('430'::text,'Limited Capacity'::text,'Low utilization or capability'::text), ('500'::text,'Not Specified'::text,'Condition unknown or not reported'::text)) condition_codes(condition_code, description, notes)
UNION ALL
 SELECT 'credibility'::text AS category,
    (credibility_codes.code)::text AS code,
    credibility_codes.description,
    credibility_codes.notes,
    4 AS sort_order
   FROM ( VALUES (1,'Confirmed by Other Sources'::text,'Multiple independent sources confirm'::text), (2,'Probably True'::text,'Corroborated by related information'::text), (3,'Possibly True'::text,'Plausible but unconfirmed'::text), (4,'Doubtful'::text,'Questionable accuracy'::text), (5,'Improbable'::text,'Likely inaccurate'::text), (6,'Cannot Be Judged'::text,'Insufficient information to assess'::text)) credibility_codes(code, description, notes)
UNION ALL
 SELECT 'reliability'::text AS category,
    reliability_codes.code,
    reliability_codes.description,
    reliability_codes.notes,
    5 AS sort_order
   FROM ( VALUES ('A'::text,'Completely Reliable'::text,'No doubt about authenticity, trustworthiness, or competency'::text), ('B'::text,'Usually Reliable'::text,'Minor doubts; historically accurate'::text), ('C'::text,'Fairly Reliable'::text,'Some doubts; generally accurate'::text), ('D'::text,'Not Usually Reliable'::text,'Significant doubts; occasionally accurate'::text), ('E'::text,'Unreliable'::text,'Lacking authenticity or competency; history of inaccuracy'::text), ('F'::text,'Cannot Be Judged'::text,'No basis for evaluation'::text)) reliability_codes(code, description, notes)
UNION ALL
 SELECT 'location_precision'::text AS category,
    precision_codes.precision_type AS code,
    precision_codes.description,
    precision_codes.notes,
    6 AS sort_order
   FROM ( VALUES ('exact'::text,'Exact Coordinates'::text,'GPS coordinates or precise geolocated position'::text), ('settlement'::text,'Settlement-level'::text,'Located in/near specific settlement (uses adm4_pcode)'::text), ('area'::text,'Tactical Area'::text,'Located somewhere within tactical area boundaries'::text), ('direction'::text,'Directional Only'::text,'General direction from reference point (lowest precision)'::text)) precision_codes(precision_type, description, notes)
  ORDER BY 5, 2;


--
-- Name: VIEW analyst_reference_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.analyst_reference_codes IS 'Pivoted reference view showing all lookup codes side-by-side for easy comparison.
All columns in one view - scroll horizontally to see all code types.';


--
-- Name: analyst_tactical_areas; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.analyst_tactical_areas AS
 SELECT tactical_area_id,
    tactical_area_name AS area_name,
    area_type,
    public.st_astext(public.st_centroid(geometry)) AS centroid_coords
   FROM spatial_ref.tactical_areas;


--
-- Name: codes_pivot_reference; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.codes_pivot_reference AS
 WITH status_agg AS (
         SELECT row_number() OVER (ORDER BY status_codes.code) AS rn,
            (((status_codes.code)::text || ': '::text) || (status_codes.description)::text) AS status_info
           FROM reference.status_codes
        ), echelon_agg AS (
         SELECT row_number() OVER (ORDER BY echelon_codes.code) AS rn,
            ((((((echelon_codes.code)::text || ': '::text) || (echelon_codes.description)::text) || ' ('::text) || (echelon_codes.symbol_display)::text) || ')'::text) AS echelon_info
           FROM reference.echelon_codes
        ), operational_agg AS (
         SELECT row_number() OVER (ORDER BY operational_condition_codes.code) AS rn,
            ((((((operational_condition_codes.code)::text || ': '::text) || (operational_condition_codes.description)::text) || ' ['::text) || (operational_condition_codes.personnel_range)::text) || ']'::text) AS operational_info
           FROM reference.operational_condition_codes
        ), credibility_agg AS (
         SELECT row_number() OVER (ORDER BY credibility_codes.code) AS rn,
            (((((credibility_codes.code)::text || ' ('::text) || (credibility_codes.letter_code)::text) || '): '::text) || (credibility_codes.description)::text) AS credibility_info
           FROM reference.credibility_codes
        ), reliability_agg AS (
         SELECT row_number() OVER (ORDER BY reliability_codes.numeric_value) AS rn,
            ((((reliability_codes.code || ' ('::text) || (reliability_codes.display_code)::text) || '): '::text) || (reliability_codes.description)::text) AS reliability_info
           FROM reference.reliability_codes
        ), reinforcement_agg AS (
         SELECT row_number() OVER (ORDER BY reinforcement_codes.code) AS rn,
            (((reinforcement_codes.code)::text || ': '::text) || (reinforcement_codes.description)::text) AS reinforcement_info
           FROM reference.reinforcement_codes
        ), max_rows AS (
         SELECT max(counts.rn) AS max_rn
           FROM ( SELECT max(status_agg.rn) AS rn
                   FROM status_agg
                UNION ALL
                 SELECT max(echelon_agg.rn) AS max
                   FROM echelon_agg
                UNION ALL
                 SELECT max(operational_agg.rn) AS max
                   FROM operational_agg
                UNION ALL
                 SELECT max(credibility_agg.rn) AS max
                   FROM credibility_agg
                UNION ALL
                 SELECT max(reliability_agg.rn) AS max
                   FROM reliability_agg
                UNION ALL
                 SELECT max(reinforcement_agg.rn) AS max
                   FROM reinforcement_agg) counts
        )
 SELECT s.status_info AS "STATUS",
    e.echelon_info AS "ECHELON",
    o.operational_info AS "OPERATIONAL_CONDITION",
    c.credibility_info AS "CREDIBILITY",
    r.reliability_info AS "RELIABILITY",
    rf.reinforcement_info AS "REINFORCEMENT"
   FROM ((((((generate_series((1)::bigint, ( SELECT max_rows.max_rn
           FROM max_rows)) gs(rn)
     LEFT JOIN status_agg s ON ((s.rn = gs.rn)))
     LEFT JOIN echelon_agg e ON ((e.rn = gs.rn)))
     LEFT JOIN operational_agg o ON ((o.rn = gs.rn)))
     LEFT JOIN credibility_agg c ON ((c.rn = gs.rn)))
     LEFT JOIN reliability_agg r ON ((r.rn = gs.rn)))
     LEFT JOIN reinforcement_agg rf ON ((rf.rn = gs.rn)))
  ORDER BY gs.rn;


--
-- Name: command_changes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.command_changes (
    change_id integer NOT NULL,
    unit_key character varying(10),
    change_type character varying(20),
    old_parent_key character varying(10),
    new_parent_key character varying(10),
    change_date date NOT NULL,
    source_id integer,
    source_confidence integer,
    is_confirmation boolean DEFAULT false,
    confirmed_change_id integer,
    from_mention_id integer,
    analyst character varying(50),
    analyst_notes text,
    created_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: command_changes_change_id_seq; Type: SEQUENCE; Schema: reference; Owner: -
--

CREATE SEQUENCE reference.command_changes_change_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: command_changes_change_id_seq; Type: SEQUENCE OWNED BY; Schema: reference; Owner: -
--

ALTER SEQUENCE reference.command_changes_change_id_seq OWNED BY reference.command_changes.change_id;


--
-- Name: context_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.context_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    usage_notes text
);


--
-- Name: TABLE context_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.context_codes IS 'MIL-STD-2525D Context codes. Always use 0 (Reality) for actual Russian ORBAT tracking.';


--
-- Name: echelon_lookup; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.echelon_lookup AS
 SELECT code,
    (((symbol_display)::text || ' - '::text) || (description)::text) AS display_name,
    description,
    symbol_display,
    hierarchy_level
   FROM reference.echelon_codes
  ORDER BY hierarchy_level;


--
-- Name: VIEW echelon_lookup; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.echelon_lookup IS 'User-friendly view of echelon codes with formatted display names for dropdowns';


--
-- Name: hq_tf_dummy_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.hq_tf_dummy_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    symbol_modifier character varying(10),
    usage_notes text
);


--
-- Name: TABLE hq_tf_dummy_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.hq_tf_dummy_codes IS 'MIL-STD-2525D HQ/Task Force/Dummy indicator codes. Most Russian units use 0 (none) or 2 (HQ).';


--
-- Name: identity_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.identity_codes (
    code integer NOT NULL,
    context_digit integer NOT NULL,
    identity_digit integer NOT NULL,
    description character varying(50) NOT NULL,
    frame_color character varying(20),
    usage_notes text
);


--
-- Name: TABLE identity_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.identity_codes IS 'MIL-STD-2525D Standard Identity codes combining Context and Identity. For Russian ORBAT tracking, use code 06 (Reality-Hostile).';


--
-- Name: COLUMN identity_codes.context_digit; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.identity_codes.context_digit IS 'First digit: 0=Reality, 1=Exercise, 2=Simulation';


--
-- Name: COLUMN identity_codes.identity_digit; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.identity_codes.identity_digit IS 'Second digit: 0=Pending, 1=Unknown, 2=Assumed Friend, 3=Friend, 4=Neutral, 5=Suspect, 6=Hostile';


--
-- Name: identity_lookup; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.identity_lookup AS
 SELECT code,
    description,
    frame_color,
    ((('Context: '::text ||
        CASE context_digit
            WHEN 0 THEN 'Reality'::text
            WHEN 1 THEN 'Exercise'::text
            WHEN 2 THEN 'Simulation'::text
            ELSE NULL::text
        END) || ' | Identity: '::text) ||
        CASE identity_digit
            WHEN 0 THEN 'Pending'::text
            WHEN 1 THEN 'Unknown'::text
            WHEN 2 THEN 'Assumed Friend'::text
            WHEN 3 THEN 'Friend'::text
            WHEN 4 THEN 'Neutral'::text
            WHEN 5 THEN 'Suspect'::text
            WHEN 6 THEN 'Hostile'::text
            ELSE NULL::text
        END) AS detailed_description,
    usage_notes
   FROM reference.identity_codes
  ORDER BY code;


--
-- Name: VIEW identity_lookup; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.identity_lookup IS 'User-friendly view of identity codes. For Russian ORBAT, use code 06 (Reality-Hostile).';


--
-- Name: identity_reality; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.identity_reality AS
 SELECT code,
    description,
    frame_color,
    usage_notes
   FROM reference.identity_codes
  WHERE (context_digit = 0)
  ORDER BY code;


--
-- Name: VIEW identity_reality; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.identity_reality IS 'Reality-context identity codes only. Use code 06 (Hostile) for Russian units.';


--
-- Name: land_installation_modifier_1; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.land_installation_modifier_1 (
    code integer NOT NULL,
    description character varying(100) NOT NULL,
    usage_notes text
);


--
-- Name: TABLE land_installation_modifier_1; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.land_installation_modifier_1 IS 'MIL-STD-2525D Modifier 1 amplifier codes specific to land installations';


--
-- Name: COLUMN land_installation_modifier_1.code; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.land_installation_modifier_1.code IS 'Numeric code for installation modifier 1';


--
-- Name: COLUMN land_installation_modifier_1.description; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.land_installation_modifier_1.description IS 'Description of the installation modifier 1 amplifier';


--
-- Name: COLUMN land_installation_modifier_1.usage_notes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.land_installation_modifier_1.usage_notes IS 'Additional remarks or usage notes';


--
-- Name: land_installation_modifier_2; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.land_installation_modifier_2 (
    code integer NOT NULL,
    description character varying(100) NOT NULL,
    usage_notes text
);


--
-- Name: TABLE land_installation_modifier_2; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.land_installation_modifier_2 IS 'MIL-STD-2525D Modifier 2 amplifier codes specific to land installations';


--
-- Name: COLUMN land_installation_modifier_2.code; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.land_installation_modifier_2.code IS 'Numeric code for installation modifier 2';


--
-- Name: COLUMN land_installation_modifier_2.description; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.land_installation_modifier_2.description IS 'Description of the installation modifier 2 amplifier';


--
-- Name: COLUMN land_installation_modifier_2.usage_notes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.land_installation_modifier_2.usage_notes IS 'Additional remarks or usage notes';


--
-- Name: modifier_1_amplifiers; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.modifier_1_amplifiers (
    code integer NOT NULL,
    description character varying(100) NOT NULL,
    usage_notes text
);


--
-- Name: TABLE modifier_1_amplifiers; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.modifier_1_amplifiers IS 'MIL-STD-2525D Modifier 1 amplifier codes for land units';


--
-- Name: COLUMN modifier_1_amplifiers.code; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.modifier_1_amplifiers.code IS 'Numeric code for modifier 1';


--
-- Name: COLUMN modifier_1_amplifiers.description; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.modifier_1_amplifiers.description IS 'Description of the modifier 1 amplifier';


--
-- Name: COLUMN modifier_1_amplifiers.usage_notes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.modifier_1_amplifiers.usage_notes IS 'Additional remarks or usage notes';


--
-- Name: modifier_2_amplifiers; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.modifier_2_amplifiers (
    code integer NOT NULL,
    description character varying(100) NOT NULL,
    usage_notes text
);


--
-- Name: TABLE modifier_2_amplifiers; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.modifier_2_amplifiers IS 'MIL-STD-2525D Modifier 2 amplifier codes for land units';


--
-- Name: COLUMN modifier_2_amplifiers.code; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.modifier_2_amplifiers.code IS 'Numeric code for modifier 2';


--
-- Name: COLUMN modifier_2_amplifiers.description; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.modifier_2_amplifiers.description IS 'Description of the modifier 2 amplifier';


--
-- Name: COLUMN modifier_2_amplifiers.usage_notes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON COLUMN reference.modifier_2_amplifiers.usage_notes IS 'Additional remarks or usage notes';


--
-- Name: source_origin_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.source_origin_codes (
    code character varying(10) NOT NULL,
    description character varying(100) NOT NULL,
    display_order integer,
    usage_notes text
);


--
-- Name: TABLE source_origin_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.source_origin_codes IS 'Classification codes for OSINT source origins. Used to provide context during mention review.';


--
-- Name: sources_reference_view; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.sources_reference_view AS
 SELECT s.source_id,
    s.source_name,
    s.channel_link,
    so.description AS source_origin,
    so.code AS source_origin_code,
    s.source_credibility,
    (((cc.letter_code)::text || ' - '::text) || (cc.description)::text) AS credibility_description,
    s.source_reliability,
    (((rc.display_code)::text || ' - '::text) || (rc.description)::text) AS reliability_description,
    s.status,
    s.analyst_notes,
    s.created_by,
    s.created_date
   FROM (((reference.sources s
     LEFT JOIN reference.source_origin_codes so ON (((s.source_origin)::text = (so.code)::text)))
     LEFT JOIN reference.credibility_codes cc ON ((s.source_credibility = cc.code)))
     LEFT JOIN reference.reliability_codes rc ON ((s.source_reliability = rc.code)))
  WHERE ((s.status)::text = 'active'::text)
  ORDER BY s.source_name;


--
-- Name: VIEW sources_reference_view; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.sources_reference_view IS 'User-friendly view of active sources with decoded reference values for analyst review.';


--
-- Name: sources_source_id_seq; Type: SEQUENCE; Schema: reference; Owner: -
--

CREATE SEQUENCE reference.sources_source_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_source_id_seq; Type: SEQUENCE OWNED BY; Schema: reference; Owner: -
--

ALTER SEQUENCE reference.sources_source_id_seq OWNED BY reference.sources.source_id;


--
-- Name: standard_russian_unit_symbology; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.standard_russian_unit_symbology AS
 SELECT 6 AS identity_,
    0 AS context,
    10 AS symbolset,
    'Use symbology_entity_codes table'::text AS symbolentity_note,
    'Use echelon_codes table'::text AS echelon_note,
    0 AS hq_indicator_default,
    2 AS hq_indicator_for_headquarters,
    0 AS status,
    'Standard hostile Russian ground unit symbology'::text AS description;


--
-- Name: VIEW standard_russian_unit_symbology; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.standard_russian_unit_symbology IS 'Standard symbology values for Russian ORBAT units. Copy these defaults when creating new units.';


--
-- Name: symbol_status_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.symbol_status_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    graphic_modifier character varying(20),
    usage_notes text
);


--
-- Name: TABLE symbol_status_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.symbol_status_codes IS 'MIL-STD-2525D Status amplifier for symbols. Use 0 (Present) for active units. This is different from the operational_condition field which tracks combat effectiveness.';


--
-- Name: symbology_by_level; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.symbology_by_level AS
 SELECT hierarchy_level,
    count(*) AS count,
    string_agg((display_name)::text, ' | '::text ORDER BY (display_name)::text) AS examples
   FROM reference.symbology_entity_codes
  GROUP BY hierarchy_level
  ORDER BY hierarchy_level;


--
-- Name: VIEW symbology_by_level; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.symbology_by_level IS 'Statistics view showing distribution of entity codes by hierarchy level.';


--
-- Name: symbology_fires; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.symbology_fires AS
 SELECT code,
    display_name,
    entity_type_name,
    entity_subtype_name,
    hierarchy_level
   FROM reference.symbology_entity_codes
  WHERE ((entity_name)::text = 'Fires'::text)
  ORDER BY code;


--
-- Name: VIEW symbology_fires; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.symbology_fires IS 'Fires entities only - artillery, air defense, mortars, etc.';


--
-- Name: symbology_lookup; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.symbology_lookup AS
 SELECT code,
    display_name,
    entity_name,
    entity_type_name,
    entity_subtype_name,
    hierarchy_level
   FROM reference.symbology_entity_codes
  ORDER BY display_name;


--
-- Name: VIEW symbology_lookup; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.symbology_lookup IS 'User-friendly view of all entity codes. Use display_name for dropdown lists in ArcGIS Pro and Python GUIs.';


--
-- Name: symbology_movement_maneuver; Type: VIEW; Schema: reference; Owner: -
--

CREATE VIEW reference.symbology_movement_maneuver AS
 SELECT code,
    display_name,
    entity_type_name,
    entity_subtype_name,
    hierarchy_level
   FROM reference.symbology_entity_codes
  WHERE ((entity_name)::text = 'Movement and Maneuver'::text)
  ORDER BY code;


--
-- Name: VIEW symbology_movement_maneuver; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON VIEW reference.symbology_movement_maneuver IS 'Movement and Maneuver entities only - the most commonly used category for ground combat units.';


--
-- Name: symbolset_codes; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.symbolset_codes (
    code integer NOT NULL,
    description character varying(50) NOT NULL,
    usage_notes text
);


--
-- Name: TABLE symbolset_codes; Type: COMMENT; Schema: reference; Owner: -
--

COMMENT ON TABLE reference.symbolset_codes IS 'MIL-STD-2525D Symbol Set codes. For ground units, use code 10 (Land Unit).';


--
-- Name: unknown_categories; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.unknown_categories (
    code character(1) NOT NULL,
    description character varying(100),
    usage_notes text
);


--
-- Name: area_update_log; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.area_update_log (
    log_id integer NOT NULL,
    action character varying(20),
    area_name character varying(255),
    area_type character varying(50),
    details text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: area_update_log_log_id_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.area_update_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: area_update_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.area_update_log_log_id_seq OWNED BY spatial_ref.area_update_log.log_id;


--
-- Name: flot_boundary_boundary_id_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.flot_boundary_boundary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


--
-- Name: flot_boundary; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.flot_boundary (
    boundary_id integer DEFAULT nextval('spatial_ref.flot_boundary_boundary_id_seq'::regclass) NOT NULL,
    boundary_name character varying(255),
    boundary_type character varying(50),
    geometry public.geometry(MultiPolygon,4326) NOT NULL,
    active boolean DEFAULT true,
    effective_date date,
    expiration_date date,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(50)
);


--
-- Name: operational_areas_area_id_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.operational_areas_area_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operational_areas_area_id_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.operational_areas_area_id_seq OWNED BY spatial_ref.operational_areas.area_id;


--
-- Name: operational_areas_gid_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.operational_areas_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operational_areas_gid_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.operational_areas_gid_seq OWNED BY spatial_ref.operational_areas.gid;


--
-- Name: operational_areas_staging; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.operational_areas_staging (
    gid integer NOT NULL,
    name character varying(254),
    shape__are numeric,
    shape__len numeric,
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: operational_areas_staging_gid_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.operational_areas_staging_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operational_areas_staging_gid_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.operational_areas_staging_gid_seq OWNED BY spatial_ref.operational_areas_staging.gid;


--
-- Name: tactical_areas_staging; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.tactical_areas_staging (
    gid integer NOT NULL,
    shape_leng numeric,
    shape_area numeric,
    tac_area_n character varying(254),
    operationa character varying(254),
    type character varying(254),
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: tactical_areas_staging_gid_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.tactical_areas_staging_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tactical_areas_staging_gid_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.tactical_areas_staging_gid_seq OWNED BY spatial_ref.tactical_areas_staging.gid;


--
-- Name: tactical_areas_tactical_area_id_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.tactical_areas_tactical_area_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tactical_areas_tactical_area_id_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.tactical_areas_tactical_area_id_seq OWNED BY spatial_ref.tactical_areas.tactical_area_id;


--
-- Name: tactical_operational_associations; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.tactical_operational_associations (
    association_id integer NOT NULL,
    tactical_area_id integer NOT NULL,
    operational_area_id integer NOT NULL,
    association_date date DEFAULT CURRENT_DATE,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: tactical_operational_associations_association_id_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.tactical_operational_associations_association_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tactical_operational_associations_association_id_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.tactical_operational_associations_association_id_seq OWNED BY spatial_ref.tactical_operational_associations.association_id;


--
-- Name: temp_operational_areas; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.temp_operational_areas (
    gid integer NOT NULL,
    name character varying(254),
    shape__are numeric,
    shape__len numeric,
    geom public.geometry(MultiPolygonZM,4326)
);


--
-- Name: temp_operational_areas_gid_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.temp_operational_areas_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: temp_operational_areas_gid_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.temp_operational_areas_gid_seq OWNED BY spatial_ref.temp_operational_areas.gid;


--
-- Name: ukrainesettlements; Type: TABLE; Schema: spatial_ref; Owner: -
--

CREATE TABLE spatial_ref.ukrainesettlements (
    gid integer NOT NULL,
    shape_leng numeric,
    adm4_en character varying(50),
    adm4_ua character varying(60),
    adm4_ru character varying(60),
    adm4_pcode character varying(50),
    adm3_en character varying(50),
    adm3_ua character varying(60),
    adm3_ru character varying(60),
    adm3_pcode character varying(50),
    adm2_en character varying(50),
    adm2_ua character varying(60),
    adm2_ru character varying(60),
    adm2_pcode character varying(50),
    adm1_en character varying(50),
    adm1_ua character varying(50),
    adm1_ru character varying(50),
    adm1_pcode character varying(50),
    adm0_en character varying(50),
    adm0_ua character varying(50),
    adm0_ru character varying(50),
    adm0_pcode character varying(50),
    date date,
    validon date,
    validto date,
    area_sqkm numeric,
    globalid character varying(38),
    hide numeric,
    shape_le_1 numeric,
    shape_area numeric,
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: ukrainesettlements_gid_seq; Type: SEQUENCE; Schema: spatial_ref; Owner: -
--

CREATE SEQUENCE spatial_ref.ukrainesettlements_gid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ukrainesettlements_gid_seq; Type: SEQUENCE OWNED BY; Schema: spatial_ref; Owner: -
--

ALTER SEQUENCE spatial_ref.ukrainesettlements_gid_seq OWNED BY spatial_ref.ukrainesettlements.gid;


--
-- Name: maid_positions_p01; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p01 FOR VALUES WITH (modulus 16, remainder 0);


--
-- Name: maid_positions_p02; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p02 FOR VALUES WITH (modulus 16, remainder 1);


--
-- Name: maid_positions_p03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p03 FOR VALUES WITH (modulus 16, remainder 2);


--
-- Name: maid_positions_p04; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p04 FOR VALUES WITH (modulus 16, remainder 3);


--
-- Name: maid_positions_p05; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p05 FOR VALUES WITH (modulus 16, remainder 4);


--
-- Name: maid_positions_p06; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p06 FOR VALUES WITH (modulus 16, remainder 5);


--
-- Name: maid_positions_p07; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p07 FOR VALUES WITH (modulus 16, remainder 6);


--
-- Name: maid_positions_p08; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p08 FOR VALUES WITH (modulus 16, remainder 7);


--
-- Name: maid_positions_p09; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p09 FOR VALUES WITH (modulus 16, remainder 8);


--
-- Name: maid_positions_p10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p10 FOR VALUES WITH (modulus 16, remainder 9);


--
-- Name: maid_positions_p11; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p11 FOR VALUES WITH (modulus 16, remainder 10);


--
-- Name: maid_positions_p12; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p12 FOR VALUES WITH (modulus 16, remainder 11);


--
-- Name: maid_positions_p13; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p13 FOR VALUES WITH (modulus 16, remainder 12);


--
-- Name: maid_positions_p14; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p14 FOR VALUES WITH (modulus 16, remainder 13);


--
-- Name: maid_positions_p15; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p15 FOR VALUES WITH (modulus 16, remainder 14);


--
-- Name: maid_positions_p16; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ATTACH PARTITION public.maid_positions_p16 FOR VALUES WITH (modulus 16, remainder 15);


--
-- Name: facility_orbat_associations association_id; Type: DEFAULT; Schema: facilities; Owner: -
--

ALTER TABLE ONLY facilities.facility_orbat_associations ALTER COLUMN association_id SET DEFAULT nextval('facilities.facility_orbat_associations_association_id_seq'::regclass);


--
-- Name: maid_orbat_associations association_id; Type: DEFAULT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_orbat_associations ALTER COLUMN association_id SET DEFAULT nextval('maid.maid_orbat_associations_association_id_seq'::regclass);


--
-- Name: maid_positions maid_observation_id; Type: DEFAULT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_positions ALTER COLUMN maid_observation_id SET DEFAULT nextval('maid.maid_positions_maid_observation_id_seq'::regclass);


--
-- Name: redeployment_events event_id; Type: DEFAULT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events ALTER COLUMN event_id SET DEFAULT nextval('orbat.redeployment_events_event_id_seq'::regclass);


--
-- Name: tactical_relocation_events relocation_id; Type: DEFAULT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events ALTER COLUMN relocation_id SET DEFAULT nextval('orbat.tactical_relocation_events_relocation_id_seq'::regclass);


--
-- Name: unit_mentions mention_id; Type: DEFAULT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions ALTER COLUMN mention_id SET DEFAULT nextval('orbat.unit_mentions_mention_id_seq'::regclass);


--
-- Name: unit_positions observation_id; Type: DEFAULT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions ALTER COLUMN observation_id SET DEFAULT nextval('orbat.unit_positions_observation_id_seq'::regclass);


--
-- Name: command_changes change_id; Type: DEFAULT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes ALTER COLUMN change_id SET DEFAULT nextval('reference.command_changes_change_id_seq'::regclass);


--
-- Name: sources source_id; Type: DEFAULT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.sources ALTER COLUMN source_id SET DEFAULT nextval('reference.sources_source_id_seq'::regclass);


--
-- Name: area_update_log log_id; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.area_update_log ALTER COLUMN log_id SET DEFAULT nextval('spatial_ref.area_update_log_log_id_seq'::regclass);


--
-- Name: operational_areas gid; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.operational_areas ALTER COLUMN gid SET DEFAULT nextval('spatial_ref.operational_areas_gid_seq'::regclass);


--
-- Name: operational_areas area_id; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.operational_areas ALTER COLUMN area_id SET DEFAULT nextval('spatial_ref.operational_areas_area_id_seq'::regclass);


--
-- Name: operational_areas_staging gid; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.operational_areas_staging ALTER COLUMN gid SET DEFAULT nextval('spatial_ref.operational_areas_staging_gid_seq'::regclass);


--
-- Name: tactical_areas tactical_area_id; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_areas ALTER COLUMN tactical_area_id SET DEFAULT nextval('spatial_ref.tactical_areas_tactical_area_id_seq'::regclass);


--
-- Name: tactical_areas_staging gid; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_areas_staging ALTER COLUMN gid SET DEFAULT nextval('spatial_ref.tactical_areas_staging_gid_seq'::regclass);


--
-- Name: tactical_operational_associations association_id; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_operational_associations ALTER COLUMN association_id SET DEFAULT nextval('spatial_ref.tactical_operational_associations_association_id_seq'::regclass);


--
-- Name: temp_operational_areas gid; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.temp_operational_areas ALTER COLUMN gid SET DEFAULT nextval('spatial_ref.temp_operational_areas_gid_seq'::regclass);


--
-- Name: ukrainesettlements gid; Type: DEFAULT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.ukrainesettlements ALTER COLUMN gid SET DEFAULT nextval('spatial_ref.ukrainesettlements_gid_seq'::regclass);


--
-- Name: facility_orbat_associations facility_orbat_associations_facility_key_unit_key_associati_key; Type: CONSTRAINT; Schema: facilities; Owner: -
--

ALTER TABLE ONLY facilities.facility_orbat_associations
    ADD CONSTRAINT facility_orbat_associations_facility_key_unit_key_associati_key UNIQUE (facility_key, unit_key, association_type, association_start_date);


--
-- Name: facility_orbat_associations facility_orbat_associations_pkey; Type: CONSTRAINT; Schema: facilities; Owner: -
--

ALTER TABLE ONLY facilities.facility_orbat_associations
    ADD CONSTRAINT facility_orbat_associations_pkey PRIMARY KEY (association_id);


--
-- Name: russian_facilities russian_facilities_pkey; Type: CONSTRAINT; Schema: facilities; Owner: -
--

ALTER TABLE ONLY facilities.russian_facilities
    ADD CONSTRAINT russian_facilities_pkey PRIMARY KEY (facility_key);


--
-- Name: maid_orbat_associations maid_orbat_associations_maid_id_associated_unit_key_associa_key; Type: CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_orbat_associations
    ADD CONSTRAINT maid_orbat_associations_maid_id_associated_unit_key_associa_key UNIQUE (maid_id, associated_unit_key, association_date_start);


--
-- Name: maid_orbat_associations maid_orbat_associations_pkey; Type: CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_orbat_associations
    ADD CONSTRAINT maid_orbat_associations_pkey PRIMARY KEY (association_id);


--
-- Name: maid_positions maid_positions_pkey; Type: CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_positions
    ADD CONSTRAINT maid_positions_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_registry maid_registry_maid_alias_key; Type: CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_registry
    ADD CONSTRAINT maid_registry_maid_alias_key UNIQUE (maid_alias);


--
-- Name: maid_registry maid_registry_pkey; Type: CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_registry
    ADD CONSTRAINT maid_registry_pkey PRIMARY KEY (maid_id);


--
-- Name: redeployment_events redeployment_events_pkey; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events
    ADD CONSTRAINT redeployment_events_pkey PRIMARY KEY (event_id);


--
-- Name: redeployment_events redeployment_events_unit_key_to_observation_id_key; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events
    ADD CONSTRAINT redeployment_events_unit_key_to_observation_id_key UNIQUE (unit_key, to_observation_id);


--
-- Name: russian_units russian_units_pkey; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_pkey PRIMARY KEY (unit_key);


--
-- Name: tactical_relocation_events tactical_relocation_events_pkey; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_pkey PRIMARY KEY (relocation_id);


--
-- Name: unit_mentions unit_mentions_pkey; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_pkey PRIMARY KEY (mention_id);


--
-- Name: unit_positions unit_positions_pkey; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT unit_positions_pkey PRIMARY KEY (observation_id);


--
-- Name: unknown_units unknown_units_pkey; Type: CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_pkey PRIMARY KEY (unknown_unit_key);


--
-- Name: maid_positions_p01 maid_positions_p01_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p01
    ADD CONSTRAINT maid_positions_p01_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p02 maid_positions_p02_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p02
    ADD CONSTRAINT maid_positions_p02_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p03 maid_positions_p03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p03
    ADD CONSTRAINT maid_positions_p03_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p04 maid_positions_p04_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p04
    ADD CONSTRAINT maid_positions_p04_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p05 maid_positions_p05_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p05
    ADD CONSTRAINT maid_positions_p05_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p06 maid_positions_p06_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p06
    ADD CONSTRAINT maid_positions_p06_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p07 maid_positions_p07_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p07
    ADD CONSTRAINT maid_positions_p07_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p08 maid_positions_p08_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p08
    ADD CONSTRAINT maid_positions_p08_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p09 maid_positions_p09_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p09
    ADD CONSTRAINT maid_positions_p09_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p10 maid_positions_p10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p10
    ADD CONSTRAINT maid_positions_p10_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p11 maid_positions_p11_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p11
    ADD CONSTRAINT maid_positions_p11_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p12 maid_positions_p12_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p12
    ADD CONSTRAINT maid_positions_p12_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p13 maid_positions_p13_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p13
    ADD CONSTRAINT maid_positions_p13_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p14 maid_positions_p14_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p14
    ADD CONSTRAINT maid_positions_p14_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p15 maid_positions_p15_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p15
    ADD CONSTRAINT maid_positions_p15_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: maid_positions_p16 maid_positions_p16_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maid_positions_p16
    ADD CONSTRAINT maid_positions_p16_pkey PRIMARY KEY (maid_id, maid_observation_id);


--
-- Name: command_changes command_changes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_pkey PRIMARY KEY (change_id);


--
-- Name: context_codes context_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.context_codes
    ADD CONSTRAINT context_codes_pkey PRIMARY KEY (code);


--
-- Name: credibility_codes credibility_codes_letter_code_key; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.credibility_codes
    ADD CONSTRAINT credibility_codes_letter_code_key UNIQUE (letter_code);


--
-- Name: credibility_codes credibility_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.credibility_codes
    ADD CONSTRAINT credibility_codes_pkey PRIMARY KEY (code);


--
-- Name: echelon_codes echelon_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.echelon_codes
    ADD CONSTRAINT echelon_codes_pkey PRIMARY KEY (code);


--
-- Name: hq_tf_dummy_codes hq_tf_dummy_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.hq_tf_dummy_codes
    ADD CONSTRAINT hq_tf_dummy_codes_pkey PRIMARY KEY (code);


--
-- Name: identity_codes identity_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.identity_codes
    ADD CONSTRAINT identity_codes_pkey PRIMARY KEY (code);


--
-- Name: land_installation_modifier_1 land_installation_modifier_1_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.land_installation_modifier_1
    ADD CONSTRAINT land_installation_modifier_1_pkey PRIMARY KEY (code);


--
-- Name: land_installation_modifier_2 land_installation_modifier_2_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.land_installation_modifier_2
    ADD CONSTRAINT land_installation_modifier_2_pkey PRIMARY KEY (code);


--
-- Name: modifier_1_amplifiers modifier_1_amplifiers_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.modifier_1_amplifiers
    ADD CONSTRAINT modifier_1_amplifiers_pkey PRIMARY KEY (code);


--
-- Name: modifier_2_amplifiers modifier_2_amplifiers_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.modifier_2_amplifiers
    ADD CONSTRAINT modifier_2_amplifiers_pkey PRIMARY KEY (code);


--
-- Name: operational_condition_codes operational_condition_codes_numeric_value_key; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.operational_condition_codes
    ADD CONSTRAINT operational_condition_codes_numeric_value_key UNIQUE (numeric_value);


--
-- Name: operational_condition_codes operational_condition_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.operational_condition_codes
    ADD CONSTRAINT operational_condition_codes_pkey PRIMARY KEY (code);


--
-- Name: reinforcement_codes reinforcement_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.reinforcement_codes
    ADD CONSTRAINT reinforcement_codes_pkey PRIMARY KEY (code);


--
-- Name: reliability_codes reliability_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.reliability_codes
    ADD CONSTRAINT reliability_codes_pkey PRIMARY KEY (code);


--
-- Name: source_origin_codes source_origin_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.source_origin_codes
    ADD CONSTRAINT source_origin_codes_pkey PRIMARY KEY (code);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (source_id);


--
-- Name: status_codes status_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.status_codes
    ADD CONSTRAINT status_codes_pkey PRIMARY KEY (code);


--
-- Name: symbol_status_codes symbol_status_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.symbol_status_codes
    ADD CONSTRAINT symbol_status_codes_pkey PRIMARY KEY (code);


--
-- Name: symbology_entity_codes symbology_entity_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.symbology_entity_codes
    ADD CONSTRAINT symbology_entity_codes_pkey PRIMARY KEY (code);


--
-- Name: symbolset_codes symbolset_codes_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.symbolset_codes
    ADD CONSTRAINT symbolset_codes_pkey PRIMARY KEY (code);


--
-- Name: unknown_categories unknown_categories_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.unknown_categories
    ADD CONSTRAINT unknown_categories_pkey PRIMARY KEY (code);


--
-- Name: area_update_log area_update_log_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.area_update_log
    ADD CONSTRAINT area_update_log_pkey PRIMARY KEY (log_id);


--
-- Name: flot_boundary flot_boundary_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.flot_boundary
    ADD CONSTRAINT flot_boundary_pkey PRIMARY KEY (boundary_id);


--
-- Name: operational_areas operational_areas_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.operational_areas
    ADD CONSTRAINT operational_areas_pkey PRIMARY KEY (area_id);


--
-- Name: operational_areas_staging operational_areas_staging_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.operational_areas_staging
    ADD CONSTRAINT operational_areas_staging_pkey PRIMARY KEY (gid);


--
-- Name: tactical_areas tactical_areas_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_areas
    ADD CONSTRAINT tactical_areas_pkey PRIMARY KEY (tactical_area_id);


--
-- Name: tactical_areas_staging tactical_areas_staging_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_areas_staging
    ADD CONSTRAINT tactical_areas_staging_pkey PRIMARY KEY (gid);


--
-- Name: tactical_operational_associations tactical_operational_associations_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_operational_associations
    ADD CONSTRAINT tactical_operational_associations_pkey PRIMARY KEY (association_id);


--
-- Name: temp_operational_areas temp_operational_areas_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.temp_operational_areas
    ADD CONSTRAINT temp_operational_areas_pkey PRIMARY KEY (gid);


--
-- Name: ukrainesettlements ukrainesettlements_pkey; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.ukrainesettlements
    ADD CONSTRAINT ukrainesettlements_pkey PRIMARY KEY (gid);


--
-- Name: tactical_areas unique_tactical_area_name_type; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_areas
    ADD CONSTRAINT unique_tactical_area_name_type UNIQUE (tactical_area_name, area_type);


--
-- Name: tactical_operational_associations unique_tactical_operational_pair; Type: CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_operational_associations
    ADD CONSTRAINT unique_tactical_operational_pair UNIQUE (tactical_area_id, operational_area_id);


--
-- Name: idx_facility_orbat_facility; Type: INDEX; Schema: facilities; Owner: -
--

CREATE INDEX idx_facility_orbat_facility ON facilities.facility_orbat_associations USING btree (facility_key);


--
-- Name: idx_facility_orbat_unit; Type: INDEX; Schema: facilities; Owner: -
--

CREATE INDEX idx_facility_orbat_unit ON facilities.facility_orbat_associations USING btree (unit_key);


--
-- Name: idx_russian_facilities_name; Type: INDEX; Schema: facilities; Owner: -
--

CREATE INDEX idx_russian_facilities_name ON facilities.russian_facilities USING gin (to_tsvector('english'::regconfig, (facility_name)::text));


--
-- Name: idx_russian_facilities_spatial; Type: INDEX; Schema: facilities; Owner: -
--

CREATE INDEX idx_russian_facilities_spatial ON facilities.russian_facilities USING gist (location);


--
-- Name: idx_russian_facilities_type; Type: INDEX; Schema: facilities; Owner: -
--

CREATE INDEX idx_russian_facilities_type ON facilities.russian_facilities USING btree (facility_type, operational_status);


--
-- Name: idx_maid_positions_batch; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_batch ON ONLY maid.maid_positions USING btree (import_batch_id);


--
-- Name: idx_maid_positions_coordinates; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_coordinates ON ONLY maid.maid_positions USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: idx_maid_positions_high_quality; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_high_quality ON ONLY maid.maid_positions USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: idx_maid_positions_maid_time; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_maid_time ON ONLY maid.maid_positions USING btree (maid_id, "timestamp" DESC);


--
-- Name: idx_maid_positions_operational; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_operational ON ONLY maid.maid_positions USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: idx_maid_positions_spatial; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_spatial ON ONLY maid.maid_positions USING gist (location);


--
-- Name: idx_maid_positions_tactical; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_positions_tactical ON ONLY maid.maid_positions USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: idx_maid_registry_alias; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_registry_alias ON maid.maid_registry USING btree (maid_alias);


--
-- Name: idx_maid_registry_status; Type: INDEX; Schema: maid; Owner: -
--

CREATE INDEX idx_maid_registry_status ON maid.maid_registry USING btree (status, priority_level);


--
-- Name: idx_redeployment_events_to_area; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_redeployment_events_to_area ON orbat.redeployment_events USING btree (to_area_id);


--
-- Name: idx_redeployment_events_unit; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_redeployment_events_unit ON orbat.redeployment_events USING btree (unit_key, redeployment_date DESC);


--
-- Name: idx_russian_units_current_area; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_current_area ON orbat.russian_units USING btree (current_operational_area_id);


--
-- Name: idx_russian_units_current_facility; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_current_facility ON orbat.russian_units USING btree (current_facility_key) WHERE (current_facility_key IS NOT NULL);


--
-- Name: idx_russian_units_facility_type; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_facility_type ON orbat.russian_units USING btree (facility_assignment_type, facility_assignment_date DESC) WHERE (facility_assignment_type IS NOT NULL);


--
-- Name: idx_russian_units_home_facility; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_home_facility ON orbat.russian_units USING btree (home_facility_key) WHERE (home_facility_key IS NOT NULL);


--
-- Name: idx_russian_units_mun; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_mun ON orbat.russian_units USING btree (mun_number);


--
-- Name: idx_russian_units_shape; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_shape ON orbat.russian_units USING gist (shape);


--
-- Name: idx_russian_units_tactical_area; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_russian_units_tactical_area ON orbat.russian_units USING btree (current_tactical_area_id);


--
-- Name: idx_tactical_relocations_date; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_tactical_relocations_date ON orbat.tactical_relocation_events USING btree (relocation_date);


--
-- Name: idx_tactical_relocations_unit; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_tactical_relocations_unit ON orbat.tactical_relocation_events USING btree (unit_key);


--
-- Name: idx_unit_mentions_analyst; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_mentions_analyst ON orbat.unit_mentions USING btree (analyst, review_status);


--
-- Name: idx_unit_mentions_date; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_mentions_date ON orbat.unit_mentions USING btree (observation_date DESC);


--
-- Name: idx_unit_mentions_detached; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_mentions_detached ON orbat.unit_mentions USING btree (is_detached_element) WHERE (is_detached_element = true);


--
-- Name: idx_unit_mentions_status; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_mentions_status ON orbat.unit_mentions USING btree (review_status, priority);


--
-- Name: idx_unit_mentions_unit; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_mentions_unit ON orbat.unit_mentions USING btree (unit_key);


--
-- Name: idx_unit_mentions_unknown_unit; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_mentions_unknown_unit ON orbat.unit_mentions USING btree (unknown_unit_key);


--
-- Name: idx_unit_positions_area; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_positions_area ON orbat.unit_positions USING btree (operational_area_id);


--
-- Name: idx_unit_positions_date; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_positions_date ON orbat.unit_positions USING btree (observation_date DESC);


--
-- Name: idx_unit_positions_pcode; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_positions_pcode ON orbat.unit_positions USING btree (adm4_pcode);


--
-- Name: idx_unit_positions_spatial; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_positions_spatial ON orbat.unit_positions USING gist (location);


--
-- Name: idx_unit_positions_tactical_area; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_positions_tactical_area ON orbat.unit_positions USING btree (tactical_area_id);


--
-- Name: idx_unit_positions_unit_key; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unit_positions_unit_key ON orbat.unit_positions USING btree (unit_key);


--
-- Name: idx_unknown_units_category; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unknown_units_category ON orbat.unknown_units USING btree (unknown_category);


--
-- Name: idx_unknown_units_parent; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unknown_units_parent ON orbat.unknown_units USING btree (parent_unit_key);


--
-- Name: idx_unknown_units_priority; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unknown_units_priority ON orbat.unknown_units USING btree (tracking_priority, mention_count DESC);


--
-- Name: idx_unknown_units_promoted; Type: INDEX; Schema: orbat; Owner: -
--

CREATE INDEX idx_unknown_units_promoted ON orbat.unknown_units USING btree (promoted_to_unit_key);


--
-- Name: maid_positions_p01_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_import_batch_id_idx ON public.maid_positions_p01 USING btree (import_batch_id);


--
-- Name: maid_positions_p01_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_latitude_longitude_idx ON public.maid_positions_p01 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p01_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_location_idx ON public.maid_positions_p01 USING gist (location);


--
-- Name: maid_positions_p01_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_location_idx1 ON public.maid_positions_p01 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p01_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p01 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p01_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_maid_id_timestamp_idx ON public.maid_positions_p01 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p01_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p01_maid_id_timestamp_idx1 ON public.maid_positions_p01 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p02_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_import_batch_id_idx ON public.maid_positions_p02 USING btree (import_batch_id);


--
-- Name: maid_positions_p02_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_latitude_longitude_idx ON public.maid_positions_p02 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p02_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_location_idx ON public.maid_positions_p02 USING gist (location);


--
-- Name: maid_positions_p02_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_location_idx1 ON public.maid_positions_p02 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p02_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p02 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p02_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_maid_id_timestamp_idx ON public.maid_positions_p02 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p02_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p02_maid_id_timestamp_idx1 ON public.maid_positions_p02 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p03_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_import_batch_id_idx ON public.maid_positions_p03 USING btree (import_batch_id);


--
-- Name: maid_positions_p03_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_latitude_longitude_idx ON public.maid_positions_p03 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p03_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_location_idx ON public.maid_positions_p03 USING gist (location);


--
-- Name: maid_positions_p03_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_location_idx1 ON public.maid_positions_p03 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p03_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p03 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p03_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_maid_id_timestamp_idx ON public.maid_positions_p03 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p03_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p03_maid_id_timestamp_idx1 ON public.maid_positions_p03 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p04_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_import_batch_id_idx ON public.maid_positions_p04 USING btree (import_batch_id);


--
-- Name: maid_positions_p04_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_latitude_longitude_idx ON public.maid_positions_p04 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p04_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_location_idx ON public.maid_positions_p04 USING gist (location);


--
-- Name: maid_positions_p04_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_location_idx1 ON public.maid_positions_p04 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p04_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p04 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p04_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_maid_id_timestamp_idx ON public.maid_positions_p04 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p04_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p04_maid_id_timestamp_idx1 ON public.maid_positions_p04 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p05_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_import_batch_id_idx ON public.maid_positions_p05 USING btree (import_batch_id);


--
-- Name: maid_positions_p05_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_latitude_longitude_idx ON public.maid_positions_p05 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p05_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_location_idx ON public.maid_positions_p05 USING gist (location);


--
-- Name: maid_positions_p05_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_location_idx1 ON public.maid_positions_p05 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p05_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p05 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p05_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_maid_id_timestamp_idx ON public.maid_positions_p05 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p05_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p05_maid_id_timestamp_idx1 ON public.maid_positions_p05 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p06_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_import_batch_id_idx ON public.maid_positions_p06 USING btree (import_batch_id);


--
-- Name: maid_positions_p06_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_latitude_longitude_idx ON public.maid_positions_p06 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p06_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_location_idx ON public.maid_positions_p06 USING gist (location);


--
-- Name: maid_positions_p06_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_location_idx1 ON public.maid_positions_p06 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p06_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p06 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p06_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_maid_id_timestamp_idx ON public.maid_positions_p06 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p06_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p06_maid_id_timestamp_idx1 ON public.maid_positions_p06 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p07_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_import_batch_id_idx ON public.maid_positions_p07 USING btree (import_batch_id);


--
-- Name: maid_positions_p07_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_latitude_longitude_idx ON public.maid_positions_p07 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p07_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_location_idx ON public.maid_positions_p07 USING gist (location);


--
-- Name: maid_positions_p07_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_location_idx1 ON public.maid_positions_p07 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p07_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p07 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p07_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_maid_id_timestamp_idx ON public.maid_positions_p07 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p07_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p07_maid_id_timestamp_idx1 ON public.maid_positions_p07 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p08_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_import_batch_id_idx ON public.maid_positions_p08 USING btree (import_batch_id);


--
-- Name: maid_positions_p08_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_latitude_longitude_idx ON public.maid_positions_p08 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p08_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_location_idx ON public.maid_positions_p08 USING gist (location);


--
-- Name: maid_positions_p08_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_location_idx1 ON public.maid_positions_p08 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p08_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p08 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p08_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_maid_id_timestamp_idx ON public.maid_positions_p08 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p08_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p08_maid_id_timestamp_idx1 ON public.maid_positions_p08 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p09_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_import_batch_id_idx ON public.maid_positions_p09 USING btree (import_batch_id);


--
-- Name: maid_positions_p09_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_latitude_longitude_idx ON public.maid_positions_p09 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p09_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_location_idx ON public.maid_positions_p09 USING gist (location);


--
-- Name: maid_positions_p09_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_location_idx1 ON public.maid_positions_p09 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p09_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p09 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p09_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_maid_id_timestamp_idx ON public.maid_positions_p09 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p09_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p09_maid_id_timestamp_idx1 ON public.maid_positions_p09 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p10_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_import_batch_id_idx ON public.maid_positions_p10 USING btree (import_batch_id);


--
-- Name: maid_positions_p10_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_latitude_longitude_idx ON public.maid_positions_p10 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p10_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_location_idx ON public.maid_positions_p10 USING gist (location);


--
-- Name: maid_positions_p10_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_location_idx1 ON public.maid_positions_p10 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p10_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p10 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p10_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_maid_id_timestamp_idx ON public.maid_positions_p10 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p10_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p10_maid_id_timestamp_idx1 ON public.maid_positions_p10 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p11_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_import_batch_id_idx ON public.maid_positions_p11 USING btree (import_batch_id);


--
-- Name: maid_positions_p11_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_latitude_longitude_idx ON public.maid_positions_p11 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p11_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_location_idx ON public.maid_positions_p11 USING gist (location);


--
-- Name: maid_positions_p11_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_location_idx1 ON public.maid_positions_p11 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p11_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p11 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p11_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_maid_id_timestamp_idx ON public.maid_positions_p11 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p11_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p11_maid_id_timestamp_idx1 ON public.maid_positions_p11 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p12_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_import_batch_id_idx ON public.maid_positions_p12 USING btree (import_batch_id);


--
-- Name: maid_positions_p12_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_latitude_longitude_idx ON public.maid_positions_p12 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p12_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_location_idx ON public.maid_positions_p12 USING gist (location);


--
-- Name: maid_positions_p12_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_location_idx1 ON public.maid_positions_p12 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p12_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p12 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p12_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_maid_id_timestamp_idx ON public.maid_positions_p12 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p12_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p12_maid_id_timestamp_idx1 ON public.maid_positions_p12 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p13_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_import_batch_id_idx ON public.maid_positions_p13 USING btree (import_batch_id);


--
-- Name: maid_positions_p13_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_latitude_longitude_idx ON public.maid_positions_p13 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p13_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_location_idx ON public.maid_positions_p13 USING gist (location);


--
-- Name: maid_positions_p13_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_location_idx1 ON public.maid_positions_p13 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p13_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p13 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p13_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_maid_id_timestamp_idx ON public.maid_positions_p13 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p13_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p13_maid_id_timestamp_idx1 ON public.maid_positions_p13 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p14_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_import_batch_id_idx ON public.maid_positions_p14 USING btree (import_batch_id);


--
-- Name: maid_positions_p14_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_latitude_longitude_idx ON public.maid_positions_p14 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p14_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_location_idx ON public.maid_positions_p14 USING gist (location);


--
-- Name: maid_positions_p14_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_location_idx1 ON public.maid_positions_p14 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p14_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p14 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p14_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_maid_id_timestamp_idx ON public.maid_positions_p14 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p14_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p14_maid_id_timestamp_idx1 ON public.maid_positions_p14 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p15_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_import_batch_id_idx ON public.maid_positions_p15 USING btree (import_batch_id);


--
-- Name: maid_positions_p15_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_latitude_longitude_idx ON public.maid_positions_p15 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p15_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_location_idx ON public.maid_positions_p15 USING gist (location);


--
-- Name: maid_positions_p15_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_location_idx1 ON public.maid_positions_p15 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p15_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p15 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p15_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_maid_id_timestamp_idx ON public.maid_positions_p15 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p15_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p15_maid_id_timestamp_idx1 ON public.maid_positions_p15 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: maid_positions_p16_import_batch_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_import_batch_id_idx ON public.maid_positions_p16 USING btree (import_batch_id);


--
-- Name: maid_positions_p16_latitude_longitude_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_latitude_longitude_idx ON public.maid_positions_p16 USING btree (latitude, longitude) WHERE ((latitude IS NOT NULL) AND (longitude IS NOT NULL));


--
-- Name: maid_positions_p16_location_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_location_idx ON public.maid_positions_p16 USING gist (location);


--
-- Name: maid_positions_p16_location_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_location_idx1 ON public.maid_positions_p16 USING gist (location) WHERE (operational_relevance IS NOT NULL);


--
-- Name: maid_positions_p16_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_maid_id_timestamp_horizontal_accuracy_idx ON public.maid_positions_p16 USING btree (maid_id, "timestamp", horizontal_accuracy) WHERE ((accuracy_class)::text = 'TACTICAL'::text);


--
-- Name: maid_positions_p16_maid_id_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_maid_id_timestamp_idx ON public.maid_positions_p16 USING btree (maid_id, "timestamp" DESC);


--
-- Name: maid_positions_p16_maid_id_timestamp_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX maid_positions_p16_maid_id_timestamp_idx1 ON public.maid_positions_p16 USING btree (maid_id, "timestamp" DESC) WHERE ((location_quality)::text = ANY (ARRAY[('HIGH'::character varying)::text, ('MEDIUM'::character varying)::text]));


--
-- Name: idx_command_changes_unit; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_command_changes_unit ON reference.command_changes USING btree (unit_key, change_date DESC);


--
-- Name: idx_identity_context; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_identity_context ON reference.identity_codes USING btree (context_digit);


--
-- Name: idx_identity_standard; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_identity_standard ON reference.identity_codes USING btree (identity_digit);


--
-- Name: idx_sources_name; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_sources_name ON reference.sources USING btree (source_name);


--
-- Name: idx_sources_origin; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_sources_origin ON reference.sources USING btree (source_origin);


--
-- Name: idx_sources_status; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_sources_status ON reference.sources USING btree (status);


--
-- Name: idx_symbology_entity_hierarchy; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_symbology_entity_hierarchy ON reference.symbology_entity_codes USING btree (hierarchy_level);


--
-- Name: idx_symbology_entity_name; Type: INDEX; Schema: reference; Owner: -
--

CREATE INDEX idx_symbology_entity_name ON reference.symbology_entity_codes USING btree (entity_name);


--
-- Name: idx_flot_boundary_active; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_flot_boundary_active ON spatial_ref.flot_boundary USING btree (active) WHERE (active = true);


--
-- Name: idx_flot_boundary_dates; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_flot_boundary_dates ON spatial_ref.flot_boundary USING btree (effective_date, expiration_date);


--
-- Name: idx_flot_boundary_geometry; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_flot_boundary_geometry ON spatial_ref.flot_boundary USING gist (geometry);


--
-- Name: idx_tactical_areas_geometry; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_tactical_areas_geometry ON spatial_ref.tactical_areas USING gist (geometry);


--
-- Name: idx_tactical_areas_type; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_tactical_areas_type ON spatial_ref.tactical_areas USING btree (area_type);


--
-- Name: idx_toa_active; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_toa_active ON spatial_ref.tactical_operational_associations USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_toa_operational; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_toa_operational ON spatial_ref.tactical_operational_associations USING btree (operational_area_id);


--
-- Name: idx_toa_tactical; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_toa_tactical ON spatial_ref.tactical_operational_associations USING btree (tactical_area_id);


--
-- Name: idx_ukrainesettlements_name; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_ukrainesettlements_name ON spatial_ref.ukrainesettlements USING btree (adm4_en);


--
-- Name: idx_ukrainesettlements_pcode; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_ukrainesettlements_pcode ON spatial_ref.ukrainesettlements USING btree (adm4_pcode);


--
-- Name: idx_ukrainesettlements_spatial; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX idx_ukrainesettlements_spatial ON spatial_ref.ukrainesettlements USING gist (geom);


--
-- Name: operational_areas_geom_idx; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX operational_areas_geom_idx ON spatial_ref.operational_areas USING gist (geom);


--
-- Name: operational_areas_staging_geom_idx; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX operational_areas_staging_geom_idx ON spatial_ref.operational_areas_staging USING gist (geom);


--
-- Name: tactical_areas_staging_geom_idx; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX tactical_areas_staging_geom_idx ON spatial_ref.tactical_areas_staging USING gist (geom);


--
-- Name: temp_operational_areas_geom_idx; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX temp_operational_areas_geom_idx ON spatial_ref.temp_operational_areas USING gist (geom);


--
-- Name: ukrainesettlements_geom_idx; Type: INDEX; Schema: spatial_ref; Owner: -
--

CREATE INDEX ukrainesettlements_geom_idx ON spatial_ref.ukrainesettlements USING gist (geom);


--
-- Name: maid_positions_p01_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p01_import_batch_id_idx;


--
-- Name: maid_positions_p01_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p01_latitude_longitude_idx;


--
-- Name: maid_positions_p01_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p01_location_idx;


--
-- Name: maid_positions_p01_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p01_location_idx1;


--
-- Name: maid_positions_p01_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p01_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p01_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p01_maid_id_timestamp_idx;


--
-- Name: maid_positions_p01_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p01_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p01_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p01_pkey;


--
-- Name: maid_positions_p02_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p02_import_batch_id_idx;


--
-- Name: maid_positions_p02_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p02_latitude_longitude_idx;


--
-- Name: maid_positions_p02_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p02_location_idx;


--
-- Name: maid_positions_p02_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p02_location_idx1;


--
-- Name: maid_positions_p02_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p02_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p02_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p02_maid_id_timestamp_idx;


--
-- Name: maid_positions_p02_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p02_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p02_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p02_pkey;


--
-- Name: maid_positions_p03_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p03_import_batch_id_idx;


--
-- Name: maid_positions_p03_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p03_latitude_longitude_idx;


--
-- Name: maid_positions_p03_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p03_location_idx;


--
-- Name: maid_positions_p03_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p03_location_idx1;


--
-- Name: maid_positions_p03_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p03_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p03_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p03_maid_id_timestamp_idx;


--
-- Name: maid_positions_p03_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p03_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p03_pkey;


--
-- Name: maid_positions_p04_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p04_import_batch_id_idx;


--
-- Name: maid_positions_p04_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p04_latitude_longitude_idx;


--
-- Name: maid_positions_p04_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p04_location_idx;


--
-- Name: maid_positions_p04_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p04_location_idx1;


--
-- Name: maid_positions_p04_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p04_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p04_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p04_maid_id_timestamp_idx;


--
-- Name: maid_positions_p04_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p04_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p04_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p04_pkey;


--
-- Name: maid_positions_p05_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p05_import_batch_id_idx;


--
-- Name: maid_positions_p05_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p05_latitude_longitude_idx;


--
-- Name: maid_positions_p05_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p05_location_idx;


--
-- Name: maid_positions_p05_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p05_location_idx1;


--
-- Name: maid_positions_p05_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p05_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p05_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p05_maid_id_timestamp_idx;


--
-- Name: maid_positions_p05_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p05_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p05_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p05_pkey;


--
-- Name: maid_positions_p06_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p06_import_batch_id_idx;


--
-- Name: maid_positions_p06_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p06_latitude_longitude_idx;


--
-- Name: maid_positions_p06_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p06_location_idx;


--
-- Name: maid_positions_p06_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p06_location_idx1;


--
-- Name: maid_positions_p06_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p06_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p06_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p06_maid_id_timestamp_idx;


--
-- Name: maid_positions_p06_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p06_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p06_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p06_pkey;


--
-- Name: maid_positions_p07_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p07_import_batch_id_idx;


--
-- Name: maid_positions_p07_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p07_latitude_longitude_idx;


--
-- Name: maid_positions_p07_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p07_location_idx;


--
-- Name: maid_positions_p07_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p07_location_idx1;


--
-- Name: maid_positions_p07_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p07_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p07_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p07_maid_id_timestamp_idx;


--
-- Name: maid_positions_p07_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p07_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p07_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p07_pkey;


--
-- Name: maid_positions_p08_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p08_import_batch_id_idx;


--
-- Name: maid_positions_p08_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p08_latitude_longitude_idx;


--
-- Name: maid_positions_p08_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p08_location_idx;


--
-- Name: maid_positions_p08_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p08_location_idx1;


--
-- Name: maid_positions_p08_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p08_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p08_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p08_maid_id_timestamp_idx;


--
-- Name: maid_positions_p08_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p08_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p08_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p08_pkey;


--
-- Name: maid_positions_p09_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p09_import_batch_id_idx;


--
-- Name: maid_positions_p09_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p09_latitude_longitude_idx;


--
-- Name: maid_positions_p09_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p09_location_idx;


--
-- Name: maid_positions_p09_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p09_location_idx1;


--
-- Name: maid_positions_p09_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p09_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p09_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p09_maid_id_timestamp_idx;


--
-- Name: maid_positions_p09_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p09_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p09_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p09_pkey;


--
-- Name: maid_positions_p10_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p10_import_batch_id_idx;


--
-- Name: maid_positions_p10_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p10_latitude_longitude_idx;


--
-- Name: maid_positions_p10_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p10_location_idx;


--
-- Name: maid_positions_p10_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p10_location_idx1;


--
-- Name: maid_positions_p10_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p10_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p10_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p10_maid_id_timestamp_idx;


--
-- Name: maid_positions_p10_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p10_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p10_pkey;


--
-- Name: maid_positions_p11_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p11_import_batch_id_idx;


--
-- Name: maid_positions_p11_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p11_latitude_longitude_idx;


--
-- Name: maid_positions_p11_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p11_location_idx;


--
-- Name: maid_positions_p11_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p11_location_idx1;


--
-- Name: maid_positions_p11_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p11_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p11_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p11_maid_id_timestamp_idx;


--
-- Name: maid_positions_p11_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p11_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p11_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p11_pkey;


--
-- Name: maid_positions_p12_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p12_import_batch_id_idx;


--
-- Name: maid_positions_p12_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p12_latitude_longitude_idx;


--
-- Name: maid_positions_p12_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p12_location_idx;


--
-- Name: maid_positions_p12_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p12_location_idx1;


--
-- Name: maid_positions_p12_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p12_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p12_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p12_maid_id_timestamp_idx;


--
-- Name: maid_positions_p12_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p12_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p12_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p12_pkey;


--
-- Name: maid_positions_p13_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p13_import_batch_id_idx;


--
-- Name: maid_positions_p13_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p13_latitude_longitude_idx;


--
-- Name: maid_positions_p13_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p13_location_idx;


--
-- Name: maid_positions_p13_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p13_location_idx1;


--
-- Name: maid_positions_p13_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p13_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p13_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p13_maid_id_timestamp_idx;


--
-- Name: maid_positions_p13_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p13_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p13_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p13_pkey;


--
-- Name: maid_positions_p14_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p14_import_batch_id_idx;


--
-- Name: maid_positions_p14_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p14_latitude_longitude_idx;


--
-- Name: maid_positions_p14_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p14_location_idx;


--
-- Name: maid_positions_p14_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p14_location_idx1;


--
-- Name: maid_positions_p14_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p14_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p14_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p14_maid_id_timestamp_idx;


--
-- Name: maid_positions_p14_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p14_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p14_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p14_pkey;


--
-- Name: maid_positions_p15_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p15_import_batch_id_idx;


--
-- Name: maid_positions_p15_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p15_latitude_longitude_idx;


--
-- Name: maid_positions_p15_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p15_location_idx;


--
-- Name: maid_positions_p15_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p15_location_idx1;


--
-- Name: maid_positions_p15_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p15_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p15_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p15_maid_id_timestamp_idx;


--
-- Name: maid_positions_p15_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p15_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p15_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p15_pkey;


--
-- Name: maid_positions_p16_import_batch_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_batch ATTACH PARTITION public.maid_positions_p16_import_batch_id_idx;


--
-- Name: maid_positions_p16_latitude_longitude_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_coordinates ATTACH PARTITION public.maid_positions_p16_latitude_longitude_idx;


--
-- Name: maid_positions_p16_location_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_spatial ATTACH PARTITION public.maid_positions_p16_location_idx;


--
-- Name: maid_positions_p16_location_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_operational ATTACH PARTITION public.maid_positions_p16_location_idx1;


--
-- Name: maid_positions_p16_maid_id_timestamp_horizontal_accuracy_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_tactical ATTACH PARTITION public.maid_positions_p16_maid_id_timestamp_horizontal_accuracy_idx;


--
-- Name: maid_positions_p16_maid_id_timestamp_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_maid_time ATTACH PARTITION public.maid_positions_p16_maid_id_timestamp_idx;


--
-- Name: maid_positions_p16_maid_id_timestamp_idx1; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.idx_maid_positions_high_quality ATTACH PARTITION public.maid_positions_p16_maid_id_timestamp_idx1;


--
-- Name: maid_positions_p16_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX maid.maid_positions_pkey ATTACH PARTITION public.maid_positions_p16_pkey;


--
-- Name: unit_positions trig_assign_operational_area; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trig_assign_operational_area BEFORE INSERT ON orbat.unit_positions FOR EACH ROW EXECUTE FUNCTION functions.assign_operational_area();


--
-- Name: unknown_units trig_assign_unknown_unit_key; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trig_assign_unknown_unit_key BEFORE INSERT ON orbat.unknown_units FOR EACH ROW EXECUTE FUNCTION functions.assign_unknown_unit_key();


--
-- Name: unit_positions trig_disperse_unit_location; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trig_disperse_unit_location BEFORE INSERT ON orbat.unit_positions FOR EACH ROW EXECUTE FUNCTION functions.disperse_unit_location();


--
-- Name: unit_positions trig_update_coordinates; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trig_update_coordinates AFTER INSERT ON orbat.unit_positions FOR EACH STATEMENT EXECUTE FUNCTION functions.trigger_update_coordinates();


--
-- Name: unit_positions trig_update_unit_from_position; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trig_update_unit_from_position AFTER INSERT ON orbat.unit_positions FOR EACH ROW EXECUTE FUNCTION functions.update_unit_from_position();


--
-- Name: russian_units trigger_clean_unit_name; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trigger_clean_unit_name BEFORE INSERT OR UPDATE ON orbat.russian_units FOR EACH ROW EXECUTE FUNCTION functions.clean_unit_name();


--
-- Name: russian_units trigger_create_initial_position; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trigger_create_initial_position AFTER INSERT ON orbat.russian_units FOR EACH ROW EXECUTE FUNCTION functions.create_initial_unit_position();


--
-- Name: russian_units trigger_sync_geometry; Type: TRIGGER; Schema: orbat; Owner: -
--

CREATE TRIGGER trigger_sync_geometry BEFORE INSERT OR UPDATE OF current_lat, current_long ON orbat.russian_units FOR EACH ROW EXECUTE FUNCTION functions.sync_russian_units_geometry();


--
-- Name: facility_orbat_associations facility_orbat_associations_facility_key_fkey; Type: FK CONSTRAINT; Schema: facilities; Owner: -
--

ALTER TABLE ONLY facilities.facility_orbat_associations
    ADD CONSTRAINT facility_orbat_associations_facility_key_fkey FOREIGN KEY (facility_key) REFERENCES facilities.russian_facilities(facility_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: facility_orbat_associations facility_orbat_associations_unit_key_fkey; Type: FK CONSTRAINT; Schema: facilities; Owner: -
--

ALTER TABLE ONLY facilities.facility_orbat_associations
    ADD CONSTRAINT facility_orbat_associations_unit_key_fkey FOREIGN KEY (unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: maid_orbat_associations maid_orbat_associations_associated_unit_key_fkey; Type: FK CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_orbat_associations
    ADD CONSTRAINT maid_orbat_associations_associated_unit_key_fkey FOREIGN KEY (associated_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: maid_orbat_associations maid_orbat_associations_maid_alias_fkey; Type: FK CONSTRAINT; Schema: maid; Owner: -
--

ALTER TABLE ONLY maid.maid_orbat_associations
    ADD CONSTRAINT maid_orbat_associations_maid_alias_fkey FOREIGN KEY (maid_alias) REFERENCES maid.maid_registry(maid_alias);


--
-- Name: russian_units fk_credibility; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT fk_credibility FOREIGN KEY (credibility) REFERENCES reference.credibility_codes(code);


--
-- Name: unit_positions fk_credibility; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT fk_credibility FOREIGN KEY (credibility) REFERENCES reference.credibility_codes(code);


--
-- Name: russian_units fk_echelon; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT fk_echelon FOREIGN KEY (echelon) REFERENCES reference.echelon_codes(code);


--
-- Name: russian_units fk_reinforced; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT fk_reinforced FOREIGN KEY (reinforced) REFERENCES reference.reinforcement_codes(code);


--
-- Name: unit_positions fk_reinforced; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT fk_reinforced FOREIGN KEY (reinforced) REFERENCES reference.reinforcement_codes(code);


--
-- Name: russian_units fk_status; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT fk_status FOREIGN KEY (status) REFERENCES reference.status_codes(code);


--
-- Name: unit_positions fk_status; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT fk_status FOREIGN KEY (status) REFERENCES reference.status_codes(code);


--
-- Name: unknown_units fk_unknown_category; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT fk_unknown_category FOREIGN KEY (unknown_category) REFERENCES reference.unknown_categories(code);


--
-- Name: redeployment_events redeployment_events_from_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events
    ADD CONSTRAINT redeployment_events_from_area_id_fkey FOREIGN KEY (from_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: redeployment_events redeployment_events_from_observation_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events
    ADD CONSTRAINT redeployment_events_from_observation_id_fkey FOREIGN KEY (from_observation_id) REFERENCES orbat.unit_positions(observation_id);


--
-- Name: redeployment_events redeployment_events_to_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events
    ADD CONSTRAINT redeployment_events_to_area_id_fkey FOREIGN KEY (to_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: redeployment_events redeployment_events_to_observation_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.redeployment_events
    ADD CONSTRAINT redeployment_events_to_observation_id_fkey FOREIGN KEY (to_observation_id) REFERENCES orbat.unit_positions(observation_id);


--
-- Name: russian_units russian_units_adcon_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_adcon_unit_key_fkey FOREIGN KEY (adcon_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: russian_units russian_units_combined_arms_army_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_combined_arms_army_key_fkey FOREIGN KEY (combined_arms_army_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: russian_units russian_units_current_facility_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_current_facility_key_fkey FOREIGN KEY (current_facility_key) REFERENCES facilities.russian_facilities(facility_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: russian_units russian_units_current_operational_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_current_operational_area_id_fkey FOREIGN KEY (current_operational_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: russian_units russian_units_current_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_current_tactical_area_id_fkey FOREIGN KEY (current_tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id);


--
-- Name: russian_units russian_units_grouping_of_forces_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_grouping_of_forces_key_fkey FOREIGN KEY (grouping_of_forces_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: russian_units russian_units_home_facility_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_home_facility_key_fkey FOREIGN KEY (home_facility_key) REFERENCES facilities.russian_facilities(facility_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: russian_units russian_units_military_district_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_military_district_key_fkey FOREIGN KEY (military_district_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: russian_units russian_units_opcon_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_opcon_unit_key_fkey FOREIGN KEY (opcon_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: russian_units russian_units_parent_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.russian_units
    ADD CONSTRAINT russian_units_parent_unit_key_fkey FOREIGN KEY (parent_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: tactical_relocation_events tactical_relocation_events_from_observation_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_from_observation_id_fkey FOREIGN KEY (from_observation_id) REFERENCES orbat.unit_positions(observation_id);


--
-- Name: tactical_relocation_events tactical_relocation_events_from_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_from_tactical_area_id_fkey FOREIGN KEY (from_tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id);


--
-- Name: tactical_relocation_events tactical_relocation_events_operational_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_operational_area_id_fkey FOREIGN KEY (operational_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: tactical_relocation_events tactical_relocation_events_to_observation_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_to_observation_id_fkey FOREIGN KEY (to_observation_id) REFERENCES orbat.unit_positions(observation_id);


--
-- Name: tactical_relocation_events tactical_relocation_events_to_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_to_tactical_area_id_fkey FOREIGN KEY (to_tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id);


--
-- Name: tactical_relocation_events tactical_relocation_events_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.tactical_relocation_events
    ADD CONSTRAINT tactical_relocation_events_unit_key_fkey FOREIGN KEY (unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unit_mentions unit_mentions_committed_to_position_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_committed_to_position_id_fkey FOREIGN KEY (committed_to_position_id) REFERENCES orbat.unit_positions(observation_id);


--
-- Name: unit_mentions unit_mentions_credibility_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_credibility_fkey FOREIGN KEY (credibility) REFERENCES reference.credibility_codes(code);


--
-- Name: unit_mentions unit_mentions_new_adcon_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_new_adcon_unit_key_fkey FOREIGN KEY (new_adcon_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unit_mentions unit_mentions_new_opcon_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_new_opcon_unit_key_fkey FOREIGN KEY (new_opcon_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unit_mentions unit_mentions_new_parent_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_new_parent_unit_key_fkey FOREIGN KEY (new_parent_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unit_mentions unit_mentions_operational_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_operational_area_id_fkey FOREIGN KEY (operational_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: unit_mentions unit_mentions_operational_condition_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_operational_condition_fkey FOREIGN KEY (operational_condition) REFERENCES reference.operational_condition_codes(code);


--
-- Name: unit_mentions unit_mentions_reinforced_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_reinforced_fkey FOREIGN KEY (reinforced) REFERENCES reference.reinforcement_codes(code);


--
-- Name: unit_mentions unit_mentions_reliability_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_reliability_fkey FOREIGN KEY (reliability) REFERENCES reference.reliability_codes(code);


--
-- Name: unit_mentions unit_mentions_source_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_source_id_fkey FOREIGN KEY (source_id) REFERENCES reference.sources(source_id);


--
-- Name: unit_mentions unit_mentions_status_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_status_fkey FOREIGN KEY (status) REFERENCES reference.status_codes(code);


--
-- Name: unit_mentions unit_mentions_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_tactical_area_id_fkey FOREIGN KEY (tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id);


--
-- Name: unit_mentions unit_mentions_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_unit_key_fkey FOREIGN KEY (unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unit_mentions unit_mentions_unknown_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_mentions
    ADD CONSTRAINT unit_mentions_unknown_unit_key_fkey FOREIGN KEY (unknown_unit_key) REFERENCES orbat.unknown_units(unknown_unit_key);


--
-- Name: unit_positions unit_positions_operational_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT unit_positions_operational_area_id_fkey FOREIGN KEY (operational_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: unit_positions unit_positions_reliability_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT unit_positions_reliability_fkey FOREIGN KEY (reliability) REFERENCES reference.reliability_codes(code);


--
-- Name: unit_positions unit_positions_source_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT unit_positions_source_id_fkey FOREIGN KEY (source_id) REFERENCES reference.sources(source_id);


--
-- Name: unit_positions unit_positions_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT unit_positions_tactical_area_id_fkey FOREIGN KEY (tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id);


--
-- Name: unit_positions unit_positions_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unit_positions
    ADD CONSTRAINT unit_positions_unit_key_fkey FOREIGN KEY (unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unknown_units unknown_units_credibility_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_credibility_fkey FOREIGN KEY (credibility) REFERENCES reference.credibility_codes(code);


--
-- Name: unknown_units unknown_units_estimated_echelon_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_estimated_echelon_fkey FOREIGN KEY (estimated_echelon) REFERENCES reference.echelon_codes(code);


--
-- Name: unknown_units unknown_units_operational_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_operational_area_id_fkey FOREIGN KEY (operational_area_id) REFERENCES spatial_ref.operational_areas(area_id);


--
-- Name: unknown_units unknown_units_operational_condition_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_operational_condition_fkey FOREIGN KEY (operational_condition) REFERENCES reference.operational_condition_codes(code);


--
-- Name: unknown_units unknown_units_parent_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_parent_unit_key_fkey FOREIGN KEY (parent_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unknown_units unknown_units_promoted_to_unit_key_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_promoted_to_unit_key_fkey FOREIGN KEY (promoted_to_unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: unknown_units unknown_units_reinforced_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_reinforced_fkey FOREIGN KEY (reinforced) REFERENCES reference.reinforcement_codes(code);


--
-- Name: unknown_units unknown_units_reliability_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_reliability_fkey FOREIGN KEY (reliability) REFERENCES reference.reliability_codes(code);


--
-- Name: unknown_units unknown_units_status_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_status_fkey FOREIGN KEY (status) REFERENCES reference.status_codes(code);


--
-- Name: unknown_units unknown_units_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: orbat; Owner: -
--

ALTER TABLE ONLY orbat.unknown_units
    ADD CONSTRAINT unknown_units_tactical_area_id_fkey FOREIGN KEY (tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id);


--
-- Name: command_changes command_changes_confirmed_change_id_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_confirmed_change_id_fkey FOREIGN KEY (confirmed_change_id) REFERENCES reference.command_changes(change_id);


--
-- Name: command_changes command_changes_from_mention_id_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_from_mention_id_fkey FOREIGN KEY (from_mention_id) REFERENCES orbat.unit_mentions(mention_id);


--
-- Name: command_changes command_changes_new_parent_key_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_new_parent_key_fkey FOREIGN KEY (new_parent_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: command_changes command_changes_old_parent_key_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_old_parent_key_fkey FOREIGN KEY (old_parent_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: command_changes command_changes_source_id_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_source_id_fkey FOREIGN KEY (source_id) REFERENCES reference.sources(source_id);


--
-- Name: command_changes command_changes_unit_key_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.command_changes
    ADD CONSTRAINT command_changes_unit_key_fkey FOREIGN KEY (unit_key) REFERENCES orbat.russian_units(unit_key);


--
-- Name: sources sources_source_credibility_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.sources
    ADD CONSTRAINT sources_source_credibility_fkey FOREIGN KEY (source_credibility) REFERENCES reference.credibility_codes(code);


--
-- Name: sources sources_source_origin_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.sources
    ADD CONSTRAINT sources_source_origin_fkey FOREIGN KEY (source_origin) REFERENCES reference.source_origin_codes(code);


--
-- Name: sources sources_source_reliability_fkey; Type: FK CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.sources
    ADD CONSTRAINT sources_source_reliability_fkey FOREIGN KEY (source_reliability) REFERENCES reference.reliability_codes(code);


--
-- Name: tactical_operational_associations tactical_operational_associations_operational_area_id_fkey; Type: FK CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_operational_associations
    ADD CONSTRAINT tactical_operational_associations_operational_area_id_fkey FOREIGN KEY (operational_area_id) REFERENCES spatial_ref.operational_areas(area_id) ON DELETE CASCADE;


--
-- Name: tactical_operational_associations tactical_operational_associations_tactical_area_id_fkey; Type: FK CONSTRAINT; Schema: spatial_ref; Owner: -
--

ALTER TABLE ONLY spatial_ref.tactical_operational_associations
    ADD CONSTRAINT tactical_operational_associations_tactical_area_id_fkey FOREIGN KEY (tactical_area_id) REFERENCES spatial_ref.tactical_areas(tactical_area_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict 1RkLnm5qmJqULLKJHWoHlmhIAvRZDqhzqdT8jXEuT0diTolHYsDMR2THsg5k2mn

