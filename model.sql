--
-- Schema for book release tracker
--

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

CREATE SCHEMA books;

SET search_path TO books,public;

-- schema version (increment whenever it changes)
CREATE TABLE schema_version ( revision integer NOT NULL );

CREATE TABLE publishers (
    id         serial PRIMARY KEY,
    name       text   NOT NULL,
    date_added timestamptz NOT NULL,
    summary    text
);

CREATE TABLE magazines (
    id         serial  PRIMARY KEY,
    title      text    NOT NULL,
    publisher  integer NOT NULL REFERENCES publishers,
    date_added timestamptz NOT NULL,
    summary    text
);

CREATE TABLE book_series (
    id           serial                   PRIMARY KEY,
    kind         integer                  NOT NULL, -- enumerated
    title        text                     NOT NULL,
    other_titles text[],
    summary      text,
    vintage      integer                  NOT NULL, -- year
    date_added   timestamptz NOT NULL,
    last_updated timestamptz NOT NULL,
    finished     boolean                  NOT NULL DEFAULT false,
    nsfw         boolean                  NOT NULL DEFAULT false,
    avg_rating   real, -- NULL means not rated (as opposed to a zero rating)
    rating_count integer                  NOT NULL DEFAULT 0,
    demographic  integer                  NOT NULL, -- enumerated, could be enum type
    magazine_id  integer                  REFERENCES magazines
);

CREATE TABLE authors (
    id          serial  PRIMARY KEY,
    name        text    NOT NULL,
    native_name text,
    aliases     text[],
    picture     boolean NOT NULL,
    birthday    date,
    bio         text,
    sex         integer NOT NULL -- we be politically correct
);

CREATE TABLE production_credits (
    series_id integer NOT NULL REFERENCES book_series,
    author_id integer NOT NULL REFERENCES authors,
    credit    integer NOT NULL -- enumerated
);

CREATE TABLE related_series (
    series_id         integer NOT NULL REFERENCES book_series,
    related_series_id integer NOT NULL REFERENCES book_series,
    relation          integer NOT NULL -- enumerated
);

CREATE TABLE translation_groups (
    id                 serial PRIMARY KEY,
    name               text   NOT NULL,
    summary            text,
    avg_rating         real,
    avg_project_rating real,
    avg_release_rate   bigint -- seconds
);

CREATE TABLE translation_projects (
    id            serial  PRIMARY KEY,
    series_id     integer NOT NULL REFERENCES book_series,
    translator_id integer NOT NULL REFERENCES translation_groups,
    start_date    timestamptz NOT NULL,
    end_date      timestamptz
);

CREATE TABLE chapters (
    id           serial  PRIMARY KEY,
    volume       integer,
    display_name text    NOT NULL,
    sort_num     integer NOT NULL,
    title        text
);

CREATE TABLE releases (
    id              serial    PRIMARY KEY,
    series_id       integer   NOT NULL REFERENCES book_series,
    translator_id   integer   NOT NULL REFERENCES translation_groups,
    project_id      integer   NOT NULL REFERENCES translation_projects,
    lang            integer   NOT NULL,
    release_date    timestamptz NOT NULL,
    notes           text,
    is_last_release boolean   NOT NULL DEFAULT false,
    chapters_ids    integer[] NOT NULL
);

CREATE TABLE users (
    id            serial  PRIMARY KEY,
    name          text    NOT NULL,
    pass          bytea   NOT NULL,
    salt          bytea   NOT NULL,
    rights        integer NOT NULL DEFAULT 0,
    vote_weight   integer NOT NULL DEFAULT 1,
    summary       text,
    register_date timestamptz NOT NULL,
    last_active   timestamptz NOT NULL,
    avatar        boolean
);

CREATE TABLE sessions (
    id          bytea   NOT NULL,
    user_id     integer NOT NULL REFERENCES users,
    expire_date timestamptz NOT NULL DEFAULT 'epoch'::timestamptz
);

-- keeps track of which chapters a user has read/owns
CREATE TABLE user_chapters (
    user_id    integer                  NOT NULL REFERENCES users,
    chapter_id integer                  NOT NULL REFERENCES chapters,
    status     integer                  NOT NULL, -- enumeration
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
-- Entities that may be associated with any number of URLs
--

-- Website, Twitter, Blog, Facebook, etc.
CREATE TABLE link_kinds (
    id   serial PRIMARY KEY,
    name text   NOT NULL
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
-- User-submitted tags and voting
--

CREATE TABLE tags (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE book_tags (
    id        serial  PRIMARY KEY,
    series_id integer NOT NULL REFERENCES book_series,
    tag_id    integer NOT NULL REFERENCES tags,
    spoiler   boolean NOT NULL,
    weight    real    NOT NULL
);

-- Use a left join to find which tags, if any, a User has voted on
-- for a given Series.
CREATE TABLE tag_consensus (
    user_id     integer NOT NULL REFERENCES users,
    book_tag_id integer NOT NULL REFERENCES book_tags,
    vote        integer NOT NULL,
    vote_date   timestamptz NOT NULL
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

CREATE TABLE favorite_tags (
    user_id integer NOT NULL REFERENCES users,
    tag_id  integer NOT NULL REFERENCES tags
);

--
-- Filters
--

CREATE TABLE filtered_groups (
    user_id  integer NOT NULL REFERENCES users,
    group_id integer NOT NULL REFERENCES translation_groups
);

CREATE TABLE filtered_tags (
    user_id integer NOT NULL REFERENCES users,
    tag_id  integer NOT NULL REFERENCES tags
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
-- Ratings and reviews
--

-- Ratings

CREATE TABLE book_ratings (
    id        serial  PRIMARY KEY,
    user_id   integer NOT NULL REFERENCES users,
    series_id integer NOT NULL REFERENCES book_series,
    rating    integer NOT NULL,
    rate_date timestamptz NOT NULL
);

CREATE TABLE translator_ratings (
    id            serial  PRIMARY KEY,
    user_id       integer NOT NULL REFERENCES users,
    translator_id integer NOT NULL REFERENCES translation_groups,
    rating        integer NOT NULL,
    rate_date     timestamptz NOT NULL
);

CREATE TABLE project_ratings (
    id         serial  PRIMARY KEY,
    user_id    integer NOT NULL REFERENCES users,
    project_id integer NOT NULL REFERENCES translation_projects,
    rating     integer NOT NULL,
    rate_date  timestamptz NOT NULL
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

CREATE TABLE project_reviews (
    id          serial  PRIMARY KEY,
    rating_id   integer NOT NULL REFERENCES project_ratings,
    body        text    NOT NULL
);

ALTER TABLE book_ratings       ADD review_id integer REFERENCES book_reviews;
ALTER TABLE translator_ratings ADD review_id integer REFERENCES translator_reviews;
ALTER TABLE project_ratings    ADD review_id integer REFERENCES project_reviews;

--
-- Triggers
--

-- update the average rating whenever a rating occurs
-- TODO: ratings may have to be cached and updates executed in batch somehow eventually
CREATE FUNCTION do_update_book_average_rating() RETURNS trigger AS $$
  BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE book_series SET avg_rating = (
            SELECT AVG(rating) FROM book_ratings r
                WHERE r.series_id = NEW.series_id ),
            rating_count = rating_count + 1;
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE book_series SET avg_rating = (
            SELECT AVG(rating) FROM book_ratings r
                WHERE r.series_id = NEW.series_id );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE book_series SET avg_rating = (
            SELECT AVG(rating) FROM book_ratings r
                WHERE r.series_id = OLD.series_id ),
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
        UPDATE translation_groups SET avg_rating = (
            SELECT AVG(rating) FROM translator_ratings r
                WHERE r.translator_id = NEW.translator_id );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE translation_groups SET avg_rating = (
            SELECT AVG(rating) FROM translator_ratings r
                WHERE r.translator_id = OLD.translator_id );
        RETURN OLD;
    END IF;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_translator_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON translator_ratings
    EXECUTE PROCEDURE do_update_translator_average_rating();

CREATE FUNCTION do_update_project_average_rating() RETURNS trigger AS $$
	BEGIN
		IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
			UPDATE translation_groups SET avg_project_rating = (
				SELECT AVG(r.rating)
			FROM project_ratings r, translation_projects p
					WHERE r.project_id = p.id
			AND r.project_id = NEW.project_id );
			RETURN NEW;
		ELSIF (TG_OP = 'DELETE') THEN
			UPDATE translation_groups SET avg_project_rating = (
				SELECT AVG(r.rating)
					FROM project_ratings r, translation_projects p
					WHERE r.project_id = p.id
					AND r.project_id = OLD.project_id );
			RETURN NEW;
		END IF;
		RETURN NULL;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_project_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON project_ratings
    EXECUTE PROCEDURE do_update_project_average_rating();

-- update the tags whenever a vote occurs
CREATE FUNCTION do_update_tags() RETURNS trigger AS $$
	DECLARE
		r      RECORD;
		weight real;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            r := NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            r := OLD;
        END IF;

        weight := (SELECT AVG(vote) FROM tag_consensus c
            WHERE c.book_tag_id = r.book_tag_id);

        IF (weight < 1) THEN
            DELETE FROM tag_consensus
                WHERE book_tag_id = r.book_tag_id;
            DELETE FROM book_tags
                WHERE id = r.book_tag_id;
        ELSE
            UPDATE book_tags AS t SET t.weight = weight
                WHERE t.id = r.book_tag_id;
        END IF;

        RETURN r;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tags
    AFTER INSERT OR UPDATE OR DELETE ON tag_consensus
    EXECUTE PROCEDURE do_update_tags();

-- update the chapters a user owns when he gets a release
CREATE FUNCTION do_update_user_chapters() RETURNS trigger AS $$
    DECLARE
		ids integer[];
        id  integer;
    BEGIN
        ids := (SELECT chapters_ids FROM releases r WHERE r.id = NEW.release_id);
        FOREACH id IN ARRAY ids
        LOOP
            INSERT INTO user_chapters (user_id, chapter_id, status)
                VALUES (NEW.user_id, id, 0); -- assuming status=0 is what we want
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

CREATE RULE user_chapters_ignore_duplicates_on_insert AS
    ON INSERT TO user_chapters
    WHERE (EXISTS (SELECT 1
        FROM user_chapters
        WHERE user_chapters.chapter_id = NEW.chapter_id))
        DO INSTEAD NOTHING;

CREATE TRIGGER update_user_chapters
    AFTER INSERT ON user_releases
    EXECUTE PROCEDURE do_update_user_chapters();

END;
