--
-- Schema for book release tracker
--

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

CREATE SCHEMA books;

SET search_path TO books,public;

CREATE EXTENSION intarray;

-- schema version (increment whenever it changes)
CREATE TABLE schema_version ( revision integer NOT NULL );
INSERT INTO schema_version VALUES (0);

--
-- Books and Authors
--

CREATE TABLE publishers (
    id         serial      PRIMARY KEY,
    name       text        NOT NULL,
    date_added timestamptz NOT NULL,
    summary    text
);

CREATE TABLE magazines (
    id         serial      PRIMARY KEY,
    title      text        NOT NULL,
    publisher  integer     NOT NULL REFERENCES publishers,
    language   text        NOT NULL,
    date_added timestamptz NOT NULL,
    summary    text
);

CREATE TYPE Demographic AS ENUM ( 'Shounen', 'Shoujo', 'Seinen', 'Josei', 'Kodomomuke', 'Seijin' );
CREATE TYPE SeriesKind AS ENUM ( 'Comic', 'Novel', 'Webcomic' );

CREATE TABLE book_series (
    id           serial      PRIMARY KEY,
    title        text        NOT NULL,
    native_title text        NOT NULL,
    other_titles text[],
    kind         SeriesKind  NOT NULL DEFAULT 'Comic',
    summary      text,
    vintage      integer     NOT NULL, -- year
    date_added   timestamptz NOT NULL,
    last_updated timestamptz NOT NULL,
    finished     boolean     NOT NULL DEFAULT false,
    nsfw         boolean     NOT NULL DEFAULT false,
    avg_rating   real, -- NULL means not rated (as opposed to a zero rating)
    rating_count integer     NOT NULL DEFAULT 0,
    demographic  Demographic NOT NULL,
    magazine_id  integer     REFERENCES magazines,
);

-- This table glues book_series and publishers to indicate if a series is
-- officially licensed in countries outside of the original
CREATE TABLE series_licenses (
	id           serial  PRIMARY KEY,
	series_id    integer NOT NULL REFERENCES book_series,
	publisher_id integer NOT NULL REFERENCES publishers,
	country      text    NOT NULL,
	when         date
);

CREATE TYPE Sex AS ENUM ( 'Male', 'Female', 'Other' );

CREATE TABLE authors (
    id          serial  PRIMARY KEY,
    given_name  text    NOT NULL,
    surname     text,
    native_name text,
    aliases     text[],
    picture     boolean NOT NULL DEFAULT false,
    birthday    date,
    bio         text,
    sex         Sex -- we be politically correct
);

CREATE TABLE production_credits (
    series_id integer NOT NULL REFERENCES book_series,
    author_id integer NOT NULL REFERENCES authors,

	-- 0001 : art
	-- 0010 : scenario
    credit    integer NOT NULL
);

CREATE TYPE SeriesRelation AS ENUM ( 'Original Work', 'Alternative Version', 'Adaptation', 'Prequel', 'Sequel', 'Spin-Off', 'Shares Character' );

CREATE TABLE related_series (
    series_id         integer        NOT NULL REFERENCES book_series,
    related_series_id integer        NOT NULL REFERENCES book_series,
    relation          SeriesRelation NOT NULL
);

--
-- Releases and Translators
--

CREATE TABLE translation_groups (
    id               serial PRIMARY KEY,
    name             text   NOT NULL,
    summary          text,
    avg_rating       real,
    avg_release_rate bigint -- seconds
);

CREATE TABLE translation_projects (
    id         serial      PRIMARY KEY,
    series_id  integer     NOT NULL REFERENCES book_series,
    start_date timestamptz NOT NULL DEFAULT 'now'::timestamptz,
    end_date   timestamptz
);

CREATE TABLE translation_project_groups (
    project_id    integer NOT NULL REFERENCES translation_projects,
    translator_id integer NOT NULL REFERENCES translation_groups
);

CREATE TABLE chapters (
	id           serial      PRIMARY KEY,
	release_date timestamptz NOT NULL DEFAULT 'epoch'::timestamptz,
	series_id    integer     NOT NULL REFERENCES book_series,
	num          integer     NOT NULL,
	volume       integer,
	notes        text
);

CREATE TABLE releases (
    id              serial      PRIMARY KEY,
    series_id       integer     NOT NULL REFERENCES book_series,
    translator_id   integer     NOT NULL REFERENCES translation_groups,
    project_id      integer     NOT NULL REFERENCES translation_projects,
	language        text        NOT NULL DEFAULT 'en',
    release_date    timestamptz NOT NULL DEFAULT 'now'::epoch,
    notes           text,
    is_last_release boolean     NOT NULL DEFAULT false,
	volume          integer,
	extra           text
);

-- Keeps track of which releases a chapter is included in
-- (may be multiple releases for a given chapter)
CREATE TABLE chapters_releases (
	id         serial  PRIMARY KEY,
	chapter_id integer NOT NULL REFERENCES chapters,
	release_id integer NOT NULL REFERENCES releases
);

--
-- Users
--

CREATE TABLE users (
    id            serial      PRIMARY KEY,
    name          text        NOT NULL,
    pass          bytea       NOT NULL,
    salt          bytea       NOT NULL,
    rights        integer     NOT NULL DEFAULT 0,
    vote_weight   integer     NOT NULL DEFAULT 1,
    summary       text,
    register_date timestamptz NOT NULL DEFAULT 'now'::timestamptz,
    last_active   timestamptz NOT NULL DEFAULT 'epoch'::timestamptz,
    avatar        boolean     NOT NULL DEFAULT false
);

CREATE TABLE sessions (
    id          bytea       NOT NULL,
    user_id     integer     NOT NULL REFERENCES users,
    expire_date timestamptz NOT NULL DEFAULT 'epoch'::timestamptz
);

CREATE TYPE ReadStatus AS ENUM ( 'Read', 'Owned', 'Skipped' );

-- keeps track of which chapters a user has read/owns
CREATE TABLE user_chapters (
    user_id    integer NOT NULL REFERENCES users,
    chapter_id integer NOT NULL REFERENCES chapters,
    status     ReadStatus,
    date_read  timestamptz
);

-- keeps track of which releases a user owns
CREATE TABLE user_releases (
    user_id    integer NOT NULL REFERENCES users,
    release_id integer NOT NULL REFERENCES releases
);

-- keeps track of users belonging to translator groups
CREATE TABLE translator_members (
    user_id       integer NOT NULL REFERENCES users,
    translator_id integer NOT NULL REFERENCES translation_groups
);

--
-- Characters
--

CREATE TYPE BloodType AS ENUM ( '0', 'A', 'B', 'AB' );

CREATE TABLE characters (
    id          serial     PRIMARY KEY,
    name        text       NOT NULL,
    native_name text       NOT NULL,
    aliases     text[],
    nationality text,
    birthday    text,
    age         integer,
    sex         Sex,
    weight      real,
    height      real,
    bust        real,
    waist       real,
    hips        real,
    blood_type  BloodType,
    description text,
    picture     boolean
);

CREATE TYPE CharacterRole AS ENUM ( 'Main', 'Secondary', 'Appears', 'Cameo' );

CREATE TABLE characters_roles (
    character_id integer       NOT NULL REFERENCES characters,
    series_id    integer       NOT NULL REFERENCES book_series,
    role         CharacterRole NOT NULL,
    appearances  integer[] --           REFERENCES chapters
);

CREATE TABLE characters_relation_kinds (
    id      serial  PRIMARY KEY,
    name    text    NOT NULL,
    opposes integer NOT NULL REFERENCES characters_relation_kinds
);

CREATE TABLE related_characters (
    character_id         integer NOT NULL REFERENCES characters,
    related_character_id integer NOT NULL REFERENCES characters,
    relation             integer NOT NULL REFERENCES characters_relation_kinds,
    ends                 boolean NOT NULL
);

--
-- User-submitted tags and voting
--

-- book/character_tag_consensus
--   Use a left join to find which tags, if any, a User has voted on
--   for a given Series/Character.

CREATE TABLE book_tags_names (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE book_tags (
    id        serial  PRIMARY KEY,
    series_id integer NOT NULL REFERENCES book_series,
    tag_id    integer NOT NULL REFERENCES book_tags_names,
    spoiler   boolean NOT NULL,
    weight    real    NOT NULL
);

CREATE TABLE book_tag_consensus (
    user_id     integer NOT NULL REFERENCES users,
    book_tag_id integer NOT NULL REFERENCES book_tags,
    vote        integer NOT NULL,
    vote_date   timestamptz NOT NULL
);

CREATE TABLE character_tags_names (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE character_tags (
    id           serial  PRIMARY KEY,
    character_id integer NOT NULL REFERENCES characters,
    tag_id       integer NOT NULL REFERENCES character_tags_names,
    spoiler      boolean NOT NULL,
    weight       real    NOT NULL
);

CREATE TABLE character_tag_consensus (
    user_id          integer NOT NULL REFERENCES users,
    character_tag_id integer NOT NULL REFERENCES character_tags,
    vote             integer NOT NULL,
    vote_date        timestamptz NOT NULL
);

--
-- Favorites
--

CREATE TABLE favorite_authors (
    user_id   integer NOT NULL REFERENCES users,
    author_id integer NOT NULL REFERENCES authors
);

CREATE TABLE favorite_series (
    user_id   integer NOT NULL REFERENCES users,
    series_id integer NOT NULL REFERENCES book_series
);

CREATE TABLE favorite_translators (
    user_id       integer NOT NULL REFERENCES users,
    translator_id integer NOT NULL REFERENCES translation_groups
);

CREATE TABLE favorite_magazines (
    user_id     integer NOT NULL REFERENCES users,
    magazine_id integer NOT NULL REFERENCES magazines
);

CREATE TABLE favorite_book_tags (
    user_id integer NOT NULL REFERENCES users,
    tag_id  integer NOT NULL REFERENCES book_tags_names
);

CREATE TABLE favorite_character_tags (
    user_id integer NOT NULL REFERENCES users,
    tag_id  integer NOT NULL REFERENCES character_tags_names
);

--
-- Filters
--

CREATE TABLE filtered_groups (
    user_id  integer NOT NULL REFERENCES users,
    group_id integer NOT NULL REFERENCES translation_groups
);

CREATE TABLE filtered_languages (
    user_id  integer NOT NULL REFERENCES users,
    language text    NOT NULL
);

CREATE TABLE filtered_book_tags (
    user_id integer NOT NULL REFERENCES users,
    tag_id  integer NOT NULL REFERENCES book_tags_names
);

CREATE TABLE filtered_character_tags (
    user_id integer NOT NULL REFERENCES users,
    tag_id  integer NOT NULL REFERENCES character_tags_names
);

--
-- Ratings and Reviews
--

-- Ratings

CREATE TABLE book_ratings (
    id        serial      PRIMARY KEY,
    user_id   integer     NOT NULL REFERENCES users,
    series_id integer     NOT NULL REFERENCES book_series,
    rating    integer     NOT NULL,
    rate_date timestamptz NOT NULL
);

CREATE TABLE translator_ratings (
    id            serial      PRIMARY KEY,
    user_id       integer     NOT NULL REFERENCES users,
    translator_id integer     NOT NULL REFERENCES translation_groups,
    rating        integer     NOT NULL,
    rate_date     timestamptz NOT NULL
);

-- Reviews
-- Reviews always have a parent rating that they are associated with,
-- but ratings do not have to include reviews. In that case,
-- *_ratings.review_id will be NULL.

CREATE TABLE book_reviews (
    id          serial  PRIMARY KEY,
    rating_id   integer NOT NULL REFERENCES book_ratings,
    body        text    NOT NULL
);

CREATE TABLE translator_reviews (
    id          serial  PRIMARY KEY,
    rating_id   integer NOT NULL REFERENCES translator_ratings,
    body        text    NOT NULL
);

ALTER TABLE book_ratings       ADD review_id integer REFERENCES book_reviews;
ALTER TABLE translator_ratings ADD review_id integer REFERENCES translator_reviews;

--
-- Entities that may be associated with any number of URLs
--

-- Website, Twitter, Blog, Facebook, etc.
CREATE TABLE link_kinds (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE publisher_links (
    publisher_id integer NOT NULL REFERENCES publishers,
    link_kind    integer NOT NULL REFERENCES link_kinds,
    url          text    NOT NULL
);

CREATE TABLE magazine_links (
    magazine_id integer NOT NULL REFERENCES magazines,
    link_kind   integer NOT NULL REFERENCES link_kinds,
    url         text    NOT NULL
);
CREATE TABLE author_links (
    author_id integer NOT NULL REFERENCES authors,
    link_kind integer NOT NULL REFERENCES link_kinds,
    url       text    NOT NULL
);

CREATE TABLE translator_links (
    translator_id integer NOT NULL REFERENCES translation_groups,
    link_kind     integer NOT NULL REFERENCES link_kinds,
    url           text    NOT NULL
);

--
-- Site news
--

CREATE TABLE news_posts (
    id          serial      PRIMARY KEY,
    user_id     integer     NOT NULL REFERENCES users,
    date_posted timestamptz NOT NULL DEFAULT 'now'::timestamptz,
    title       text        NOT NULL,
    body        text        NOT NULL
);

--
-- Triggers
--

-- update the average rating whenever a rating occurs
-- TODO: ratings may have to be cached and updates executed in batch somehow eventually
CREATE FUNCTION do_update_book_average_rating() RETURNS trigger AS $$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            UPDATE book_series
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM book_ratings r
                        WHERE r.series_id = NEW.series_id
                ),
            rating_count = rating_count + 1;
            RETURN NEW;
        ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE book_series
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM book_ratings r
                        WHERE r.series_id = NEW.series_id
                );
            RETURN NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            UPDATE book_series
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM book_ratings r
                        WHERE r.series_id = OLD.series_id
                ),
                rating_count = rating_count - 1;
            RETURN OLD;
        END IF;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_book_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON book_ratings
    EXECUTE PROCEDURE do_update_book_average_rating();

CREATE FUNCTION do_update_translator_average_rating() RETURNS trigger AS $$
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            UPDATE translation_groups
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM translator_ratings r
                        WHERE r.translator_id = NEW.translator_id
                );
            RETURN NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            UPDATE translation_groups
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM translator_ratings r
                        WHERE r.translator_id = OLD.translator_id
                );
            RETURN OLD;
        END IF;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_translator_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON translator_ratings
    EXECUTE PROCEDURE do_update_translator_average_rating();

-- update the tags whenever a vote occurs
CREATE FUNCTION do_update_book_tags() RETURNS trigger AS $$
    DECLARE
        r      RECORD;
        weight real;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            r := NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            r := OLD;
        END IF;

        weight := (
            SELECT AVG(vote)
                FROM book_tag_consensus c
                WHERE c.book_tag_id = r.book_tag_id
        );
        IF (weight < 1) THEN
            DELETE FROM book_tag_consensus
                WHERE book_tag_id = r.book_tag_id;
            DELETE FROM book_tags_names
                WHERE id = r.book_tag_id;
        ELSE
            UPDATE book_tags_names AS t
                SET t.weight = weight
                WHERE t.id = r.book_tag_id;
        END IF;

        RETURN r;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_book_tags
    AFTER INSERT OR UPDATE OR DELETE ON book_tag_consensus
    EXECUTE PROCEDURE do_update_book_tags();

CREATE FUNCTION do_update_character_tags() RETURNS trigger AS $$
    DECLARE
        r      RECORD;
        weight real;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            r := NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            r := OLD;
        END IF;

        weight := (
            SELECT AVG(vote)
                FROM character_tag_consensus c
                WHERE c.character_tag_id = r.character_tag_id
        );

        IF (weight < 1) THEN
            DELETE FROM character_tag_consensus
                WHERE character_tag_id = r.character_tag_id;
            DELETE FROM character_tags_names
                WHERE id = r.character_tag_id;
        ELSE
            UPDATE character_tags_names AS t
                SET t.weight = weight
                WHERE t.id = r.character_tag_id;
        END IF;

        RETURN r;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_character_tags
    AFTER INSERT OR UPDATE OR DELETE ON character_tag_consensus
    EXECUTE PROCEDURE do_update_character_tags();

-- update the chapters a user owns when he gets a release
CREATE FUNCTION do_update_user_chapters() RETURNS trigger AS $$
    BEGIN
		INSERT INTO user_chapters (user_id, chapter_id, status)
			VALUES (
				NEW.user_id,
				( SELECT id
						FROM chapters
						WHERE chapters_releases.chapter_id = chapters.id
						AND chapters_releases.release_id = NEW.release_id
				),
				'Owned'
			);
    END;
$$ LANGUAGE plpgsql;

CREATE RULE user_chapters_ignore_duplicates_on_insert AS
    ON INSERT TO user_chapters
    WHERE (EXISTS (
        SELECT 1
        FROM user_chapters
        WHERE user_chapters.chapter_id = NEW.chapter_id
    ))
    DO INSTEAD NOTHING;

CREATE TRIGGER update_user_chapters
    AFTER INSERT ON user_releases
    EXECUTE PROCEDURE do_update_user_chapters();

-- update the object of a series relation
CREATE FUNCTION do_update_series_relations() RETURNS trigger AS $$
    DECLARE
        related_relation SeriesRelation;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            CASE NEW.relation
                WHEN 'Alternative Version' THEN
                    related_relation := 'Alternative Version';
                WHEN 'Adaptation' THEN
                    related_relation := 'Original Work';
                WHEN 'Prequel' THEN
                    related_relation := 'Sequel';
                WHEN 'Sequel' THEN
                    related_relation := 'Prequel';
                WHEN 'Spin-Off' THEN
                    related_relation := 'Original Work';
                WHEN 'Shares Character' THEN
                    related_relation := 'Shares Character';
            END CASE;
        END IF;
        CASE TG_OP
            WHEN 'INSERT' THEN
                INSERT INTO related_series (series_id, related_series_id, relation)
                    VALUES (NEW.related_series_id, NEW.series_id, related_relation);
            WHEN 'UPDATE' THEN
                UPDATE related_series
                    SET relation = related_relation
						WHERE series_id = NEW.related_series_id
                        AND related_series_id = NEW.series_id;
            WHEN 'DELETE' THEN
                DELETE FROM related_series
                    WHERE series_id = OLD.related_series_id
					AND related_series_id = OLD.series_id;
        END CASE;
    END;
$$ LANGUAGE plpgsql;

CREATE RULE series_relations_ignore_duplicates_on_insert AS
    ON INSERT TO related_series
    WHERE (EXISTS (
        SELECT 1
        FROM related_series WHERE
			series_id = NEW.series_id
            AND related_series_id = NEW.related_series_id
    ))
    DO INSTEAD NOTHING;

CREATE TRIGGER update_series_relations
    AFTER INSERT OR UPDATE OR DELETE ON related_series
    EXECUTE PROCEDURE do_update_series_relations();

-- update the object of a character relation
CREATE FUNCTION do_update_character_relations() RETURNS trigger AS $$
    BEGIN
        CASE TG_OP
            WHEN 'INSERT' THEN
                INSERT INTO related_characters (character_id, related_character_id, relation, ends)
                    VALUES (NEW.related_character_id, NEW.character_id, (
                        SELECT opposes
                            FROM characters_relation_kinds
                            WHERE id = NEW.relation
                        ),
                        NEW.ends);
            WHEN 'UPDATE' THEN
                UPDATE related_characters
                    SET relation = (
                        SELECT opposes
                            FROM characters_relation_kinds
                            WHERE id = NEW.relation
                        ),
                        ends = NEW.ends
                    WHERE relation = OLD.relation
                        AND character_id = NEW.related_character_id
                        AND related_character_id = NEW.character_id;
            WHEN 'DELETE' THEN
                DELETE FROM related_characters
                    WHERE relation = OLD.relation
                        AND character_id = OLD.related_character_id
                        AND related_character_id = OLD.character_id;
        END CASE;
    END;
$$ LANGUAGE plpgsql;

CREATE RULE characters_relations_ignore_duplicates_on_insert AS
    ON INSERT TO related_characters
    WHERE (EXISTS (
        SELECT 1
        FROM related_characters
            WHERE (
                relation = NEW.relation
                    OR relation = (SELECT opposes
                        FROM characters_relation_kinds
                        WHERE id = NEW.relation
                    )
            )
                AND character_id = NEW.character_id
                AND related_character_id = NEW.related_character_id
    ))
    DO INSTEAD NOTHING;

CREATE TRIGGER update_character_relations
    AFTER INSERT OR UPDATE OR DELETE ON related_characters
    EXECUTE PROCEDURE do_update_character_relations();

END;
