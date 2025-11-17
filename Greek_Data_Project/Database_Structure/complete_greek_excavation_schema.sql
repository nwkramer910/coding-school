-- ============================================================================
-- Greek Archaeological Database (Archaiologikon Deltion)
-- PostgreSQL + PostGIS Schema - Multi-Schema Architecture
-- ============================================================================
-- Organized into 5 PostgreSQL schemas:
--   1. spatial     - Geographic/cadastral data, coordinate systems
--   2. excavations - Core excavation data, finds, burials, architecture
--   3. reference   - Lookup tables, chronology, bibliographies
--   4. analysis    - Derived sites, functional interpretations
--   5. imagery     - Plans, photographs, georeferencing
-- ============================================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS spatial;
CREATE SCHEMA IF NOT EXISTS excavations;
CREATE SCHEMA IF NOT EXISTS reference;
CREATE SCHEMA IF NOT EXISTS analysis;
CREATE SCHEMA IF NOT EXISTS imagery;

SET search_path TO spatial, excavations, reference, analysis, imagery, public;

-- ============================================================================
-- SCHEMA 1: reference - Lookup Tables & Reference Data
-- ============================================================================

-- Archaeological periods
CREATE TABLE reference.chronology_master (
    period_code         VARCHAR(5) PRIMARY KEY,
    period_name         VARCHAR(50) NOT NULL,
    start_date          INTEGER,  -- Negative for BCE
    end_date            INTEGER,  -- Negative for BCE
    parent_period       VARCHAR(5),
    display_order       INTEGER NOT NULL,
    FOREIGN KEY (parent_period) REFERENCES reference.chronology_master(period_code)
);

INSERT INTO reference.chronology_master (period_code, period_name, start_date, end_date, parent_period, display_order) VALUES
('EH', 'Early Helladic', -3100, -2000, NULL, 1),
('MH', 'Middle Helladic', -2000, -1600, NULL, 2),
('LH', 'Late Helladic', -1600, -1100, NULL, 3),
('SM', 'Submycenaean', -1100, -1050, NULL, 4),
('PG', 'Protogeometric', -1050, -900, NULL, 5),
('GM', 'Geometric', -900, -700, NULL, 6),
('AR', 'Archaic', -700, -480, NULL, 7),
('CL', 'Classical', -480, -323, NULL, 8),
('HL', 'Hellenistic', -323, -31, NULL, 9),
('RO', 'Roman', -31, 400, NULL, 10),
('BZ', 'Byzantine', 330, 1453, NULL, 11),
('UD', 'Undated', NULL, NULL, NULL, 99);

-- Pottery phases for detailed chronology
CREATE TABLE reference.chronology_pottery_phases (
    phase_id            SERIAL PRIMARY KEY,
    period_code         VARCHAR(5) NOT NULL REFERENCES reference.chronology_master(period_code),
    phase_name          VARCHAR(50),
    phase_locale        TEXT,
    phase_origin_location GEOMETRY(Point, 2100),
    start_date          INTEGER,
    end_date            INTEGER,
    pottery_style       VARCHAR(100),
    style_notes         TEXT,
    bibliography        TEXT
);

-- Lead votive chronology
CREATE TABLE reference.chronology_lead_votives (
    phase_id            SERIAL PRIMARY KEY,
    period_code         VARCHAR(5) NOT NULL REFERENCES reference.chronology_master(period_code),
    phase_name          VARCHAR(50),
    start_date          INTEGER,
    end_date            INTEGER,
    characteristics     TEXT,
    bibliography        TEXT
);

-- Site functional categories (12 types)
CREATE TABLE reference.functional_categories (
    function_id         SERIAL PRIMARY KEY,
    function_name       VARCHAR(50) UNIQUE NOT NULL,
    function_description TEXT,
    criteria            TEXT
);

INSERT INTO reference.functional_categories (function_name, function_description) VALUES
('Public Space', 'Agoras, public buildings, civic spaces'),
('Religion/Cult', 'Sanctuaries, temples, votive deposits, hero shrines'),
('Transport', 'Roads, bridges, gates'),
('Fortification', 'City walls, defensive structures'),
('Water Supply/Drainage', 'Wells, cisterns, aqueducts, drainage'),
('Bathing', 'Baths, bathing complexes'),
('Domestic', 'Houses, residential areas'),
('Production', 'Workshops, kilns, craft production'),
('Commerce', 'Markets, commercial buildings'),
('Funerary', 'Cemeteries, tombs, burial areas'),
('Education', 'Gymnasia, educational facilities'),
('Unknown', 'Function cannot be determined');

-- Find object categories (42 types)
CREATE TABLE reference.finds_categories (
    category_id         SERIAL PRIMARY KEY,
    category_name       VARCHAR(50) UNIQUE NOT NULL,
    category_description TEXT,
    typical_contexts    TEXT
);

INSERT INTO reference.finds_categories (category_name) VALUES
('Acroteria'), ('Amphorae'), ('Architectural Reliefs'), ('Architectural Sculpture'),
('Architecture'), ('Bells'), ('Bone Animal'), ('Bone Carvings'), ('Bone Figurines'),
('Bone Objects'), ('Bronze Figurines'), ('Bronze Objects'), ('Bronze Vessels'),
('Burial'), ('Clay Masks'), ('Clay Plaques'), ('Coins'), ('Domestic Utensils'),
('Glass Objects'), ('Hearth'), ('Inscriptions'), ('Iron Objects'), ('Jewelry'),
('Lead Figurines'), ('Loom Weights'), ('Miniature Pottery'), ('Mosaics'),
('Musical Instruments'), ('Perirrhanteria'), ('Pins'), ('Pipes'), ('Pottery'),
('Relief Pithoi'), ('Road'), ('Roof Tiles'), ('Seals'), ('Statuary'), ('Stone Objects'),
('Stone Reliefs'), ('Terracotta Figurines'), ('Weapons'), ('Wells');

-- Sources (provenance tracking for all data)
CREATE TABLE reference.sources (
    source_id           SERIAL PRIMARY KEY,
    source_type         VARCHAR(50) NOT NULL,  -- 'journal', 'excavation_report', 'monograph', 'archive', 'interview', 'personal_comm', etc.
    source_name         VARCHAR(255) NOT NULL,
    author              VARCHAR(255),
    year_published      INTEGER,
    publisher           VARCHAR(255),
    citation            TEXT,  -- Full bibliographic citation
    digital_location    TEXT,  -- URL or file path if digitized
    physical_location   TEXT,  -- Archive, library, etc.
    language            VARCHAR(20) DEFAULT 'Greek',
    reliability_score   INTEGER CHECK (reliability_score BETWEEN 1 AND 5),  -- 1=low, 5=high
    notes               TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bibliography (AD journal entries) - specific source type
CREATE TABLE reference.bibliographies (
    record_number       SERIAL PRIMARY KEY,
    source_id           INTEGER REFERENCES reference.sources(source_id),  -- Link to general sources
    journal_name        VARCHAR(50) DEFAULT 'Αρχαιολογικόν Δελτίον',
    volume              INTEGER,
    year                INTEGER,
    page_range          VARCHAR(20),
    title               VARCHAR(500),
    article_name        VARCHAR(500),
    entry_number        VARCHAR(50) UNIQUE,  -- e.g., AD.16.1960.Sparti
    greek_text          TEXT,
    english_text        TEXT,
    associated_excavations TEXT[],
    document_link       TEXT,
    plate               BOOLEAN DEFAULT FALSE,
    image               BOOLEAN DEFAULT FALSE,
    plan                BOOLEAN DEFAULT FALSE,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes               TEXT
);

-- ============================================================================
-- SCHEMA 2: spatial - Geographic & Cadastral Data
-- ============================================================================

-- Settlements (archaeological sites/cities)
CREATE TABLE spatial.settlements (
    settlement_id       SERIAL PRIMARY KEY,
    settlement_name_en  VARCHAR(100) NOT NULL,
    settlement_name_el  VARCHAR(100) NOT NULL,
    settlement_type     VARCHAR(50),  -- ancient_city, sanctuary, cemetery
    modern_municipality VARCHAR(100),
    prefecture          VARCHAR(50),
    region              VARCHAR(50),
    settlement_geometry GEOMETRY(Point, 2100),
    notes               TEXT
);

-- Greek administrative regions (Περιφέρειες)
CREATE TABLE spatial.greek_regions (
    region_id           SERIAL PRIMARY KEY,
    region_name_en      VARCHAR(100),
    region_name_el      VARCHAR(100),
    geometry            GEOMETRY(MultiPolygon, 2100)
);

-- Greek prefectures (Νομοί/Περιφερειακές Ενότητες)
CREATE TABLE spatial.greek_prefectures (
    prefecture_id       SERIAL PRIMARY KEY,
    region_id           INTEGER REFERENCES spatial.greek_regions(region_id),
    prefecture_name_en  VARCHAR(100),
    prefecture_name_el  VARCHAR(100),
    geometry            GEOMETRY(MultiPolygon, 2100)
);

-- Greek municipalities (Δήμοι)
CREATE TABLE spatial.greek_municipalities (
    municipality_id     SERIAL PRIMARY KEY,
    prefecture_id       INTEGER REFERENCES spatial.greek_prefectures(prefecture_id),
    municipality_name_en VARCHAR(100),
    municipality_name_el VARCHAR(100),
    geometry            GEOMETRY(MultiPolygon, 2100)
);

-- Building blocks (cadastral blocks within settlements)
CREATE TABLE spatial.building_blocks (
    objectid            SERIAL PRIMARY KEY,
    id                  INTEGER,
    settlement_id       INTEGER REFERENCES spatial.settlements(settlement_id),
    bb_number           VARCHAR(20) NOT NULL,
    settlement_name_en  VARCHAR(100),
    settlement_name_el  VARCHAR(100),
    name                VARCHAR(20),
    name2               VARCHAR(50),
    bb_latitude         DOUBLE PRECISION,
    bb_longitude        DOUBLE PRECISION,
    geometry            GEOMETRY(Polygon, 4326),
    geometry_greek_grid GEOMETRY(Polygon, 2100),
    UNIQUE (settlement_id, bb_number)
);

-- Plots master (KAEK cadastral parcels)
CREATE TABLE spatial.plots_master (
    kaek                BIGINT PRIMARY KEY,
    settlement_id       INTEGER REFERENCES spatial.settlements(settlement_id),
    bb_number           VARCHAR(20),
    tile_number         VARCHAR(20),
    address             VARCHAR(200),
    municipality        VARCHAR(100),
    prefecture          VARCHAR(50),
    region              VARCHAR(50),
    plots_location      GEOMETRY(Point, 2100),
    plots_lat           DOUBLE PRECISION,
    plots_long          DOUBLE PRECISION,
    plots_easting       DOUBLE PRECISION,
    plots_northing      DOUBLE PRECISION,
    owner_name_el       VARCHAR(100),
    owner_name_en       VARCHAR(100),
    excavated           BOOLEAN DEFAULT FALSE,
    excavations         INTEGER DEFAULT 0,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes               TEXT,
    FOREIGN KEY (settlement_id, bb_number)
        REFERENCES spatial.building_blocks(settlement_id, bb_number)
);

-- British survey grid (Sparta-specific)
CREATE TABLE spatial.british_grid (
    objectid            SERIAL PRIMARY KEY,
    id                  INTEGER,
    grid_name           VARCHAR(5),  -- e.g., P14
    geometry            GEOMETRY(Polygon, 2100)
);

-- Legacy coordinate systems (for site-specific historical grids)
CREATE TABLE spatial.legacy_coordinate_systems (
    system_id           SERIAL PRIMARY KEY,
    settlement_id       INTEGER REFERENCES spatial.settlements(settlement_id),
    system_name         VARCHAR(100) NOT NULL,  -- e.g., 'British School 1906', 'French Survey 1920'
    system_origin       VARCHAR(100),  -- Who created it
    year_established    INTEGER,
    datum_description   TEXT,  -- Description of the local coordinate system
    origin_point_local  JSONB,  -- Original grid origin {x: 0, y: 0}
    origin_point_ggrs87 GEOMETRY(Point, 2100),  -- Same point in GGRS87
    rotation_degrees    DOUBLE PRECISION DEFAULT 0,  -- Rotation from grid north to true north
    scale_factor        DOUBLE PRECISION DEFAULT 1.0,  -- Scale correction if needed
    transformation_type VARCHAR(50) DEFAULT 'affine',  -- 'affine', 'polynomial', 'rubber_sheet'
    transformation_params JSONB,  -- Additional transformation parameters
    accuracy_meters     DOUBLE PRECISION,  -- Estimated accuracy of transformation
    control_points      JSONB,  -- Array of control points [{local: [x,y], ggrs87: [e,n]}, ...]
    source_id           INTEGER REFERENCES reference.sources(source_id),
    notes               TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Excavation coordinates in legacy systems (preserve original survey data)
CREATE TABLE spatial.excavation_legacy_coords (
    coord_id            SERIAL PRIMARY KEY,
    excavation_id       VARCHAR(30) REFERENCES excavations.excavations(excavation_id),
    system_id           INTEGER REFERENCES spatial.legacy_coordinate_systems(system_id),
    local_x             DOUBLE PRECISION,
    local_y             DOUBLE PRECISION,
    local_z             DOUBLE PRECISION,  -- Elevation in local datum
    original_notation   VARCHAR(100),  -- As recorded, e.g., "P14 SW corner"
    transformed_geom    GEOMETRY(Point, 2100),  -- Auto-calculated GGRS87 position
    transformation_error DOUBLE PRECISION,  -- Residual error from transformation
    notes               TEXT
);

-- 100km x 100km grid tiles
CREATE TABLE spatial.grid_100x100km (
    oid                 SERIAL PRIMARY KEY,
    tile_name           VARCHAR(10) UNIQUE,
    geometry            GEOMETRY(Polygon, 2100)
);

-- 10km x 10km grid tiles
CREATE TABLE spatial.grid_10x10km (
    oid                 SERIAL PRIMARY KEY,
    tile_name           VARCHAR(20),
    geometry            GEOMETRY(Polygon, 2100)
);

-- Sparta-specific topographic features
CREATE TABLE spatial.sparta_hills (
    objectid            SERIAL PRIMARY KEY,
    id                  INTEGER,
    elevation           DOUBLE PRECISION,
    name                TEXT,
    geometry            GEOMETRY(Polygon, 2100)
);

CREATE TABLE spatial.sparta_monuments (
    fid                 SERIAL PRIMARY KEY,
    name                TEXT,
    geometry            GEOMETRY(Point, 2100)
);

-- ============================================================================
-- SCHEMA 3: excavations - Core Excavation Data
-- ============================================================================

-- Individual excavation events
CREATE TABLE excavations.excavations (
    excavation_id       VARCHAR(30) PRIMARY KEY,  -- Format: 48.006.050.088.0002.1962
    kaek                BIGINT REFERENCES spatial.plots_master(kaek),
    confidence          VARCHAR(10) CHECK (confidence IN ('none', 'low', 'medium', 'high')),
    record_number       INTEGER REFERENCES reference.bibliographies(record_number),
    excavation_year     INTEGER,
    excavation_start_date DATE,
    excavation_end_date DATE,
    excavation_length   INTEGER,  -- Auto-calculated days
    excavation_area     DOUBLE PRECISION,  -- square meters
    reporter            VARCHAR(100),
    excavator           VARCHAR(100),
    chronological_range TEXT,
    functions           TEXT,
    notes               TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(50),
    modified_by         VARCHAR(50)
);

-- ============================================================================
-- THREE-TIER FINDS ARCHITECTURE
-- ============================================================================

-- TIER 1: Finds assemblages (batch-level reporting)
CREATE TABLE excavations.finds_assemblages (
    assemblage_id       SERIAL PRIMARY KEY,
    excavation_id       VARCHAR(30) NOT NULL REFERENCES excavations.excavations(excavation_id),
    category_id         INTEGER NOT NULL REFERENCES reference.finds_categories(category_id),
    find_context        TEXT,
    find_depth          DOUBLE PRECISION,
    reported_description TEXT,  -- Excavator's original text
    reported_date_text  VARCHAR(100),  -- e.g., "Archaic period"
    clean_date_code     VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    reported_quantity_text VARCHAR(50),  -- "many", "numerous"
    estimated_quantity  DOUBLE PRECISION,  -- Numerical assessment
    exact_count         BOOLEAN DEFAULT FALSE,
    quantity_confidence INTEGER CHECK (quantity_confidence BETWEEN 1 AND 4),
    has_individual_objects BOOLEAN DEFAULT FALSE,
    assemblage_notes    TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(50)
);

-- TIER 2: Individual catalogued objects
CREATE TABLE excavations.finds_objects (
    object_id           SERIAL PRIMARY KEY,
    assemblage_id       INTEGER REFERENCES excavations.finds_assemblages(assemblage_id),
    object_number       VARCHAR(50),  -- Museum number (e.g., MS 14956)
    category_id         INTEGER NOT NULL REFERENCES reference.finds_categories(category_id),
    excavation_id       VARCHAR(30) NOT NULL REFERENCES excavations.excavations(excavation_id),
    find_context        TEXT,
    find_depth          DOUBLE PRECISION,
    description         TEXT,
    dimensions          JSONB,  -- {height: 8.3, width: 4.2, unit: "cm"}
    weight              DOUBLE PRECISION,
    reported_date_text  VARCHAR(100),
    clean_date_code     VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    is_standalone       BOOLEAN DEFAULT FALSE,
    object_notes        TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(50)
);

-- TIER 3: Flexible attributes for assemblages or objects
CREATE TABLE excavations.finds_attributes (
    attribute_id        SERIAL PRIMARY KEY,
    assemblage_id       INTEGER REFERENCES excavations.finds_assemblages(assemblage_id),
    object_id           INTEGER REFERENCES excavations.finds_objects(object_id),
    attribute_type      VARCHAR(50) NOT NULL,  -- material, origin, style, cult_association
    attribute_value     TEXT NOT NULL,
    confidence          VARCHAR(10) CHECK (confidence IN ('low', 'medium', 'high')),
    attributed_by       VARCHAR(50),  -- excavator, interpreter, algorithm
    attribution_notes   TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (assemblage_id IS NOT NULL OR object_id IS NOT NULL)
);

-- Complex/uncertain dating for finds
CREATE TABLE excavations.finds_chronology (
    chronology_id       SERIAL PRIMARY KEY,
    assemblage_id       INTEGER REFERENCES excavations.finds_assemblages(assemblage_id),
    object_id           INTEGER REFERENCES excavations.finds_objects(object_id),
    reported_date_text  TEXT,
    clean_date_code     VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    date_confidence     VARCHAR(10) CHECK (date_confidence IN ('low', 'medium', 'high')),
    dating_method       VARCHAR(50),  -- stratigraphy, style, C14
    dating_notes        TEXT,
    CHECK (assemblage_id IS NOT NULL OR object_id IS NOT NULL)
);

-- AI-assisted date staging for review
CREATE TABLE excavations.finds_date_staging (
    staging_id          SERIAL PRIMARY KEY,
    assemblage_id       INTEGER REFERENCES excavations.finds_assemblages(assemblage_id),
    object_id           INTEGER REFERENCES excavations.finds_objects(object_id),
    reported_date_text  TEXT,
    suggested_period_codes VARCHAR(5)[],
    suggestion_confidence DOUBLE PRECISION,
    suggestion_method   VARCHAR(50),
    needs_review        BOOLEAN DEFAULT TRUE,
    reviewed_by         VARCHAR(50),
    review_date         TIMESTAMP,
    final_period_code   VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    CHECK (assemblage_id IS NOT NULL OR object_id IS NOT NULL)
);

-- ============================================================================
-- ARCHITECTURAL FEATURES
-- ============================================================================

CREATE TABLE excavations.walls (
    wall_id             SERIAL PRIMARY KEY,
    excavation_id       VARCHAR(30) NOT NULL REFERENCES excavations.excavations(excavation_id),
    image_number        VARCHAR(50),
    wall_type           VARCHAR(50),  -- peribolos, retaining, house_wall, fortification
    high_find_depth     DOUBLE PRECISION,
    low_find_depth      DOUBLE PRECISION,
    orientation         VARCHAR(20),
    orientation_degrees INTEGER CHECK (orientation_degrees BETWEEN 0 AND 360),
    wall_length         DOUBLE PRECISION,
    preserved_height    DOUBLE PRECISION,
    construction_material VARCHAR(100),
    construction_technique VARCHAR(50),  -- polygonal, ashlar, mudbrick
    wall_geometry       GEOMETRY(LineString, 2100),
    notes               TEXT
);

CREATE TABLE excavations.roads (
    road_id             SERIAL PRIMARY KEY,
    excavation_id       VARCHAR(30) NOT NULL REFERENCES excavations.excavations(excavation_id),
    image_number        VARCHAR(50),
    high_find_depth     DOUBLE PRECISION,
    low_find_depth      DOUBLE PRECISION,
    orientation         VARCHAR(20),
    orientation_degrees INTEGER CHECK (orientation_degrees BETWEEN 0 AND 360),
    road_length         DOUBLE PRECISION,
    road_width          DOUBLE PRECISION,
    surface_material    VARCHAR(100),
    roadbed_layers      JSONB,
    associated_drains   INTEGER[],
    associated_pipes    INTEGER[],
    connects_to         INTEGER REFERENCES excavations.roads(road_id),
    road_geometry       GEOMETRY(LineString, 2100),
    notes               TEXT
);

-- Water conduits (pipes and drains combined)
CREATE TABLE excavations.water_conduits (
    conduit_id          SERIAL PRIMARY KEY,
    excavation_id       VARCHAR(30) NOT NULL REFERENCES excavations.excavations(excavation_id),
    conduit_type        VARCHAR(20) NOT NULL CHECK (conduit_type IN ('pipe', 'drain', 'channel', 'aqueduct')),
    subtype             VARCHAR(50),  -- e.g., 'terracotta pipe', 'stone drain'
    image_number        VARCHAR(50),
    high_find_depth     DOUBLE PRECISION,
    low_find_depth      DOUBLE PRECISION,
    orientation         VARCHAR(20),
    orientation_degrees INTEGER CHECK (orientation_degrees BETWEEN 0 AND 360),
    length              DOUBLE PRECISION,
    -- Dimensional properties (use what's appropriate for type)
    diameter            DOUBLE PRECISION,  -- For pipes
    width               DOUBLE PRECISION,  -- For drains/channels
    depth               DOUBLE PRECISION,  -- For drains/channels
    capacity            DOUBLE PRECISION,  -- Estimated flow capacity
    construction_material VARCHAR(100),
    flow_direction      VARCHAR(20),
    connects_to         INTEGER REFERENCES excavations.water_conduits(conduit_id),
    conduit_geometry    GEOMETRY(LineString, 2100),
    notes               TEXT
);

CREATE TABLE excavations.mosaics (
    mosaic_id           SERIAL PRIMARY KEY,
    excavation_id       VARCHAR(30) NOT NULL REFERENCES excavations.excavations(excavation_id),
    mosaic_alias        VARCHAR(100),
    cult_iconography    TEXT,
    political_iconography TEXT,
    construction_material VARCHAR(100),
    find_depth          DOUBLE PRECISION,
    orientation         VARCHAR(20),
    orientation_degrees INTEGER,
    dimensions          JSONB,
    condition           VARCHAR(50),
    mosaic_geometry     GEOMETRY(Polygon, 2100),
    image_number        VARCHAR(50),
    notes               TEXT
);

-- ============================================================================
-- BURIALS
-- ============================================================================

CREATE TABLE excavations.burials (
    burial_id           SERIAL PRIMARY KEY,
    kaek                BIGINT REFERENCES spatial.plots_master(kaek),
    excavation_id       VARCHAR(30) REFERENCES excavations.excavations(excavation_id),
    chronology          VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    date_confidence     VARCHAR(10) CHECK (date_confidence IN ('low', 'medium', 'high')),
    tomb_type           VARCHAR(50),
    construction        VARCHAR(100),
    covered             BOOLEAN,
    covering            VARCHAR(100),
    orientation         VARCHAR(20),
    length              DOUBLE PRECISION,
    width               DOUBLE PRECISION,
    depth               DOUBLE PRECISION,
    burial_type         VARCHAR(50),  -- inhumation, cremation
    remains             VARCHAR(50),
    age                 VARCHAR(50),
    sex                 VARCHAR(20),
    secondary_burial    BOOLEAN DEFAULT FALSE,
    grave_goods         TEXT,
    burial_geometry     GEOMETRY(Point, 2100),
    notes               TEXT,
    record_number       INTEGER REFERENCES reference.bibliographies(record_number),
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE excavations.burial_grave_goods (
    burial_id           INTEGER NOT NULL REFERENCES excavations.burials(burial_id) ON DELETE CASCADE,
    object_id           INTEGER NOT NULL REFERENCES excavations.finds_objects(object_id),
    object_position     VARCHAR(50),
    object_description  TEXT,
    PRIMARY KEY (burial_id, object_id)
);

-- ============================================================================
-- SPECIALIZED FIND TYPES
-- ============================================================================

CREATE TABLE excavations.inscriptions (
    inscription_id      SERIAL PRIMARY KEY,
    object_id           INTEGER REFERENCES excavations.finds_objects(object_id),
    assemblage_id       INTEGER REFERENCES excavations.finds_assemblages(assemblage_id),
    inscription_text    TEXT,
    inscription_leiden  TEXT,  -- Leiden convention format
    inscription_xml_link TEXT,
    language            VARCHAR(20),
    script_type         VARCHAR(50),
    translation         TEXT,
    notes               TEXT,
    CHECK (object_id IS NOT NULL OR assemblage_id IS NOT NULL)
);

CREATE TABLE excavations.coins (
    coin_id             SERIAL PRIMARY KEY,
    object_id           INTEGER NOT NULL REFERENCES excavations.finds_objects(object_id),
    denomination        VARCHAR(50),
    mint                VARCHAR(50),
    ruler               VARCHAR(100),
    date_minted         VARCHAR(50),
    obverse_description TEXT,
    reverse_description TEXT,
    weight              DOUBLE PRECISION,
    diameter            DOUBLE PRECISION,
    metal_composition   VARCHAR(50),
    condition           VARCHAR(50),
    reference_catalog   VARCHAR(100),
    catalog_number      VARCHAR(50)
);

-- ============================================================================
-- SCHEMA 4: analysis - Analytical & Derived Data
-- ============================================================================

-- Archaeological sites (derived from plots/excavations)
CREATE TABLE analysis.sites_master (
    site_id             SERIAL PRIMARY KEY,
    site_type           VARCHAR(50),  -- single_plot, multi_plot_complex, inferred
    primary_kaek        BIGINT REFERENCES spatial.plots_master(kaek),
    associated_excavation_ids TEXT[],
    site_name           VARCHAR(100),
    site_geometry       GEOMETRY(Polygon, 2100),
    formation_method    VARCHAR(50),  -- excavation_defined, spatial_clustering
    site_confidence     VARCHAR(10) CHECK (site_confidence IN ('low', 'medium', 'high')),
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(50),
    notes               TEXT
);

-- Junction: plots to sites
CREATE TABLE analysis.plots_to_sites (
    kaek                BIGINT NOT NULL REFERENCES spatial.plots_master(kaek),
    site_id             INTEGER NOT NULL REFERENCES analysis.sites_master(site_id),
    plot_role           VARCHAR(20),  -- primary, secondary, peripheral
    spatial_coverage_pct INTEGER,
    PRIMARY KEY (kaek, site_id)
);

-- Site functional interpretations by period
CREATE TABLE analysis.sites_functions (
    function_assignment_id SERIAL PRIMARY KEY,
    site_id             INTEGER NOT NULL REFERENCES analysis.sites_master(site_id),
    function_id         INTEGER NOT NULL REFERENCES reference.functional_categories(function_id),
    period_code         VARCHAR(5) NOT NULL REFERENCES reference.chronology_master(period_code),
    priority_rank       INTEGER,  -- 1=primary, 2=secondary
    confidence          VARCHAR(10) CHECK (confidence IN ('low', 'medium', 'high')),
    evidence_basis      TEXT,
    attribution_source  VARCHAR(50),
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(50),
    notes               TEXT,
    UNIQUE (site_id, period_code, priority_rank)
);

-- Specialized religious site data
CREATE TABLE analysis.religious_sites (
    religious_site_id   SERIAL PRIMARY KEY,
    site_id             INTEGER NOT NULL REFERENCES analysis.sites_master(site_id),
    excavation_id       VARCHAR(30) REFERENCES excavations.excavations(excavation_id),
    cult_association    VARCHAR(100),
    cult_type           VARCHAR(50),  -- heroic, chthonic, olympian, uncertain
    has_architecture    BOOLEAN DEFAULT FALSE,
    architectural_elements TEXT,
    architectural_style VARCHAR(50),
    architectural_layout VARCHAR(50),
    plaque_count        INTEGER,
    lead_figurine_count INTEGER,
    miniature_pottery_count INTEGER,
    votive_assemblage_character VARCHAR(50),
    sanctuary_type      VARCHAR(50),
    period_active_start VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    period_active_end   VARCHAR(5) REFERENCES reference.chronology_master(period_code),
    notes               TEXT
);

-- ============================================================================
-- SCHEMA 5: imagery - Images & Georeferencing
-- ============================================================================

CREATE TABLE imagery.images (
    image_number        VARCHAR(50) PRIMARY KEY,
    entry_number        VARCHAR(50) REFERENCES reference.bibliographies(entry_number),
    image_type          VARCHAR(20),  -- plate, image, plan
    image_link          TEXT,
    excavation_id       VARCHAR(30) REFERENCES excavations.excavations(excavation_id),
    kaek                BIGINT REFERENCES spatial.plots_master(kaek),
    image_description   TEXT,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE imagery.georef_plans (
    georef_id           SERIAL PRIMARY KEY,
    image_number        VARCHAR(50) NOT NULL REFERENCES imagery.images(image_number),
    excavation_id       VARCHAR(30) REFERENCES excavations.excavations(excavation_id),
    kaek                BIGINT REFERENCES spatial.plots_master(kaek),
    georef_method       VARCHAR(50),
    source_crs          VARCHAR(50),
    target_crs          VARCHAR(50) DEFAULT 'EPSG:2100',
    transformation_params JSONB,
    control_points      JSONB,
    rmse_x              DOUBLE PRECISION,
    rmse_y              DOUBLE PRECISION,
    rmse_total          DOUBLE PRECISION,
    georef_software     VARCHAR(50),
    georef_date         DATE,
    georef_by           VARCHAR(50),
    quality_flag        VARCHAR(20),  -- Auto-calculated: excellent, good, fair, poor
    georef_notes        TEXT
);

CREATE TABLE imagery.georef_control_points (
    gcp_id              SERIAL PRIMARY KEY,
    georef_id           INTEGER NOT NULL REFERENCES imagery.georef_plans(georef_id) ON DELETE CASCADE,
    point_number        INTEGER,
    source_x            DOUBLE PRECISION,
    source_y            DOUBLE PRECISION,
    target_x            DOUBLE PRECISION,
    target_y            DOUBLE PRECISION,
    target_z            DOUBLE PRECISION,
    point_type          VARCHAR(50),
    residual_x          DOUBLE PRECISION,
    residual_y          DOUBLE PRECISION,
    enabled             BOOLEAN DEFAULT TRUE,
    notes               TEXT
);

CREATE TABLE imagery.georef_features_extracted (
    feature_id          SERIAL PRIMARY KEY,
    georef_id           INTEGER NOT NULL REFERENCES imagery.georef_plans(georef_id) ON DELETE CASCADE,
    feature_type        VARCHAR(50),
    feature_geometry    GEOMETRY(Geometry, 2100),
    feature_label       TEXT,
    confidence          VARCHAR(10),
    extraction_date     DATE,
    extraction_notes    TEXT
);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update modified_date timestamp
CREATE OR REPLACE FUNCTION update_modified_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_excavations_modified
    BEFORE UPDATE ON excavations.excavations
    FOR EACH ROW EXECUTE FUNCTION update_modified_date();

CREATE TRIGGER tr_plots_modified
    BEFORE UPDATE ON spatial.plots_master
    FOR EACH ROW EXECUTE FUNCTION update_modified_date();

-- Calculate excavation length
CREATE OR REPLACE FUNCTION update_excavation_length()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.excavation_start_date IS NOT NULL AND NEW.excavation_end_date IS NOT NULL THEN
        NEW.excavation_length = NEW.excavation_end_date - NEW.excavation_start_date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_excavation_length
    BEFORE INSERT OR UPDATE ON excavations.excavations
    FOR EACH ROW EXECUTE FUNCTION update_excavation_length();

-- Auto-calculate georef quality flag
CREATE OR REPLACE FUNCTION set_georef_quality_flag()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.rmse_total < 0.5 THEN
        NEW.quality_flag = 'excellent';
    ELSIF NEW.rmse_total < 1.0 THEN
        NEW.quality_flag = 'good';
    ELSIF NEW.rmse_total < 2.0 THEN
        NEW.quality_flag = 'fair';
    ELSE
        NEW.quality_flag = 'poor';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_georef_quality
    BEFORE INSERT OR UPDATE ON imagery.georef_plans
    FOR EACH ROW EXECUTE FUNCTION set_georef_quality_flag();

-- Transform building block WGS84 to Greek Grid
CREATE OR REPLACE FUNCTION transform_bb_to_greek_grid()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.geometry IS NOT NULL THEN
        NEW.geometry_greek_grid = ST_Transform(NEW.geometry, 2100);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_bb_transform
    BEFORE INSERT OR UPDATE ON spatial.building_blocks
    FOR EACH ROW EXECUTE FUNCTION transform_bb_to_greek_grid();

-- ============================================================================
-- SPATIAL INDEXES
-- ============================================================================

CREATE INDEX idx_settlements_geom ON spatial.settlements USING GIST(settlement_geometry);
CREATE INDEX idx_bb_geom ON spatial.building_blocks USING GIST(geometry);
CREATE INDEX idx_bb_geom_greek ON spatial.building_blocks USING GIST(geometry_greek_grid);
CREATE INDEX idx_plots_geom ON spatial.plots_master USING GIST(plots_location);
CREATE INDEX idx_british_grid_geom ON spatial.british_grid USING GIST(geometry);
CREATE INDEX idx_grid_100km_geom ON spatial.grid_100x100km USING GIST(geometry);
CREATE INDEX idx_grid_10km_geom ON spatial.grid_10x10km USING GIST(geometry);
CREATE INDEX idx_hills_geom ON spatial.sparta_hills USING GIST(geometry);
CREATE INDEX idx_monuments_geom ON spatial.sparta_monuments USING GIST(geometry);
CREATE INDEX idx_regions_geom ON spatial.greek_regions USING GIST(geometry);
CREATE INDEX idx_prefectures_geom ON spatial.greek_prefectures USING GIST(geometry);
CREATE INDEX idx_municipalities_geom ON spatial.greek_municipalities USING GIST(geometry);

CREATE INDEX idx_walls_geom ON excavations.walls USING GIST(wall_geometry);
CREATE INDEX idx_roads_geom ON excavations.roads USING GIST(road_geometry);
CREATE INDEX idx_water_conduits_geom ON excavations.water_conduits USING GIST(conduit_geometry);
CREATE INDEX idx_mosaics_geom ON excavations.mosaics USING GIST(mosaic_geometry);
CREATE INDEX idx_burials_geom ON excavations.burials USING GIST(burial_geometry);

CREATE INDEX idx_sites_geom ON analysis.sites_master USING GIST(site_geometry);
CREATE INDEX idx_extracted_features_geom ON imagery.georef_features_extracted USING GIST(feature_geometry);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX idx_excavations_year ON excavations.excavations(excavation_year);
CREATE INDEX idx_excavations_kaek ON excavations.excavations(kaek);
CREATE INDEX idx_finds_assemblages_exc ON excavations.finds_assemblages(excavation_id);
CREATE INDEX idx_finds_assemblages_cat ON excavations.finds_assemblages(category_id);
CREATE INDEX idx_finds_objects_num ON excavations.finds_objects(object_number);
CREATE INDEX idx_plots_tile ON spatial.plots_master(tile_number);
CREATE INDEX idx_plots_settlement ON spatial.plots_master(settlement_id);
CREATE INDEX idx_burials_period ON excavations.burials(chronology);

-- Full-text search on bibliography
CREATE INDEX idx_bib_greek_text ON reference.bibliographies USING gin(to_tsvector('simple', greek_text));
CREATE INDEX idx_bib_english_text ON reference.bibliographies USING gin(to_tsvector('english', english_text));

-- ============================================================================
-- USER ROLES
-- ============================================================================

-- Admin role: full access
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sparta_admin') THEN
        CREATE ROLE sparta_admin;
    END IF;
END $$;

GRANT ALL PRIVILEGES ON SCHEMA spatial, excavations, reference, analysis, imagery TO sparta_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA spatial, excavations, reference, analysis, imagery TO sparta_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA spatial, excavations, reference, analysis, imagery TO sparta_admin;

-- Editor role: read/write excavations, analysis, imagery; read-only reference, spatial
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sparta_editor') THEN
        CREATE ROLE sparta_editor;
    END IF;
END $$;

GRANT USAGE ON SCHEMA spatial, excavations, reference, analysis, imagery TO sparta_editor;
GRANT SELECT ON ALL TABLES IN SCHEMA spatial, reference TO sparta_editor;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA excavations, analysis, imagery TO sparta_editor;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA excavations, analysis, imagery TO sparta_editor;

-- Reader role: read-only access
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sparta_reader') THEN
        CREATE ROLE sparta_reader;
    END IF;
END $$;

GRANT USAGE ON SCHEMA spatial, excavations, reference, analysis, imagery TO sparta_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA spatial, excavations, reference, analysis, imagery TO sparta_reader;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON SCHEMA spatial IS 'Geographic and cadastral data, coordinate systems, administrative boundaries';
COMMENT ON SCHEMA excavations IS 'Core excavation data: finds, architectural features, burials';
COMMENT ON SCHEMA reference IS 'Lookup tables: chronology, categories, bibliographies';
COMMENT ON SCHEMA analysis IS 'Analytical and derived data: sites, functional interpretations';
COMMENT ON SCHEMA imagery IS 'Images, plans, and georeferencing data';

COMMENT ON TABLE excavations.excavations IS 'Individual excavation events, keyed by unique ID format: tile.kaek.sequence.year';
COMMENT ON TABLE excavations.finds_assemblages IS 'Tier 1: Batch-level find reporting from AD entries';
COMMENT ON TABLE excavations.finds_objects IS 'Tier 2: Individual catalogued objects with museum numbers';
COMMENT ON TABLE excavations.finds_attributes IS 'Tier 3: Flexible attributes for assemblages or objects';
COMMENT ON TABLE analysis.sites_master IS 'Archaeological sites derived from plot/excavation analysis';
