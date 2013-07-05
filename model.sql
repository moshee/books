--
-- Schema for book release tracker
--

-- schema version (increment whenever it changes)
CREATE TABLE schema_version ( revision integer NOT NULL );

CREATE TABLE book_series (
    id           serial                   PRIMARY KEY NOT NULL,
    kind         integer                  NOT NULL, -- enumerated
    title        text                     NOT NULL,
    other_titles text[],
    summary      text,
    vintage      integer                  NOT NULL, -- year
    date_added   timestamp with time zone NOT NULL,
    last_updated timestamp with time zone NOT NULL,
    finished     boolean                  NOT NULL DEFAULT false,
    nsfw         boolean                  NOT NULL DEFAULT false,

    -- NULL means not rated (as opposed to a zero rating)
    avg_rating   real,
    rating_count integer NOT NULL DEFAULT 0,

    demographic   integer NOT NULL, -- enumerated, could be enum type
    magazine      integer REFERENCES serializations
);

CREATE TABLE authors (
    id          serial  PRIMARY KEY NOT NULL,
    name        text    NOT NULL,
    native_name text,
    aliases     text[],
    picture     boolean NOT NULL,
    birthday    date,
    bio         text,
    sex         integer NOT NULL -- we be politically correct
);

CREATE TABLE production_credits (
    book_series_id integer NOT NULL REFERENCES book_series,
    author_id      integer NOT NULL REFERENCES authors,
    credit         integer NOT NULL -- enumerated
);

CREATE TABLE related_series (
    book_series_id    integer NOT NULL REFERENCES book_series,
    related_series_id integer NOT NULL REFERENCES book_series,
    relation          integer NOT NULL -- enumerated
);

CREATE TABLE translation_groups (
    id                 serial PRIMARY KEY NOT NULL,
    name               text   NOT NULL,
    summary            text,
    avg_rating         real,
    avg_project_rating real,
    avg_release_rate   bigint -- seconds
);

CREATE TABLE chapters (
    id         serial      PRIMARY KEY NOT NULL,
    volume     integer,
    num        integer,
    title      text,
    actual_num integer     NOT NULL
);

CREATE TABLE releases (
    id              serial    PRIMARY KEY NOT NULL,
    book_series_id  integer   NOT NULL REFERENCES book_series,
    translator_id   integer   NOT NULL REFERENCES translator_groups,
    project_id      integer   NOT NULL REFERENCES translation_projects,
    lang            integer   NOT NULL,
    release_date    timestamp with time zone NOT NULL,
    notes           text,
    is_last_release boolean   NOT NULL DEFAULT false,
    chapters_ids    integer[] NOT NULL REFERENCES chapters,
);

CREATE TABLE translation_projects (
    id            serial  PRIMARY KEY NOT NULL,
    series_id     integer NOT NULL REFERENCES book_series,
    translator_id integer NOT NULL REFERENCES translator_groups,
    start_date    timestamp with time zone NOT NULL,
    end_date      timestamp with time zone
)

CREATE TABLE users (
    id            serial  PRIMARY KEY NOT NULL,
    name          text    NOT NULL,
    pass          bytea   NOT NULL,
    salt          bytea   NOT NULL,
    rights        integer NOT NULL DEFAULT 0,
    vote_weight   integer NOT NULL DEFAULT 1,
    summary       text,
    register_date timestamp with time zone NOT NULL,
    last_active   timestamp with time zone NOT NULL,
    avatar        boolean
);

CREATE TABLE sessions (
    id          bytea   NOT NULL,
    user_id     integer NOT NULL REFERENCES users,
    expire_date timestamp with time zone NOT NULL DEFAULT epoch
);

-- keeps track of which releases a user has read/owns
CREATE TABLE user_releases (
    user_id    integer                  NOT NULL REFERENCES users,
    release_id integer                  NOT NULL REFERENCES releases,
    status     integer                  NOT NULL, -- enumeration
    date_read  timestamp with time zone
);

-- keeps track of users belonging to translator groups
CREATE TABLE translator_members (
    user_id       integer NOT NULL REFERENCES users,
    translator_id integer NOT NULL REFERENCES translation_groups
);

CREATE TABLE magazines (
    id         serial  PRIMARY KEY NOT NULL,
    title      text    NOT NULL,
    publisher  integer NOT NULL REFERENCES publishers,
    date_added timestamp with time zone NOT NULL,
    summary    text
);

CREATE TABLE publishers (
    id         serial PRIMARY KEY NOT NULL,
    name       text   NOT NULL,
    date_added timestamp with time zone NOT NULL,
    summary    text
);

--
-- Entities that may be associated with any number of URLs
--

-- Website, Twitter, Blog, Facebook, etc.
CREATE TABLE link_kinds (
    id   serial PRIMARY KEY NOT NULL,
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
    id   serial PRIMARY KEY NOT NULL,
    name text   NOT NULL
);

CREATE TABLE book_tags (
    id             serial PRIMARY KEY NOT NULL,
    book_series_id integer            NOT NULL REFERENCES book_series,
    tag_id         integer            NOT NULL REFERENCES tags,
    spoiler        boolean            NOT NULL,
    weight         real               NOT NULL
);

-- Use a left join to find which tags, if any, a User has voted on
-- for a given Series.
CREATE TABLE tag_consensus (
    user_id     integer                  NOT NULL REFERENCES users,
    book_tag_id integer                  NOT NULL REFERENCES book_tags,
    vote        integer                  NOT NULL,
    vote_date   timestamp with time zone NOT NULL
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

--
-- Ratings and reviews
--

-- Ratings

CREATE TABLE book_ratings (
    id        serial  PRIMARY KEY NOT NULL,
    user_id   integer NOT NULL REFERENCES users,
    series_id integer NOT NULL REFERENCES book_series,
    review_id integer REFERENCES book_reviews,
    rating    integer NOT NULL,
    rate_date timestamp with time zone NOT NULL
);

CREATE TABLE translator_ratings (
    id            serial  PRIMARY KEY NOT NULL,
    user_id       integer NOT NULL REFERENCES users,
    translator_id integer NOT NULL REFERENCES translation_groups,
    review_id     integer REFERENCES translator_reviews,
    rating        integer NOT NULL,
    rate_date     timestamp with time zone NOT NULL
);

CREATE TABLE project_ratings (
    id         serial  PRIMARY KEY NOT NULL,
    user_id    integer NOT NULL REFERENCES users,
    project_id integer NOT NULL REFERENCES translation_projects,
    review_id  integer REFERENCES project_reviews,
    rating     integer NOT NULL,
    rate_date  timestamp with time zone NOT NULL
);

-- Reviews
-- Reviews always have a parent rating that they are associated with,
-- but ratings do not have to include reviews. In that case,
-- *_ratings.review_id will be NULL.

CREATE TABLE book_reviews (
    id          serial  PRIMARY KEY NOT NULL,
    rating_id   integer NOT NULL REFERENCES book_ratings,
    body        text    NOT NULL
);

CREATE TABLE translator_reviews (
    id          serial  PRIMARY KEY NOT NULL,
    rating_id   integer NOT NULL REFERENCES translator_ratings,
    body        text    NOT NULL
);

CREATE TABLE project_reviews (
    id          serial  PRIMARY KEY NOT NULL,
    rating_id   integer NOT NULL REFERENCES project_ratings,
    body        text    NOT NULL
);

-- Triggers

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
    ELSE IF (TG_OP = 'UPDATE') THEN
        UPDATE book_series SET avg_rating = (
            SELECT AVG(rating) FROM book_ratings r
                WHERE r.series_id = NEW.series_id );
        RETURN NEW;
    ELSE IF (TG_OP = 'DELETE') THEN
        UPDATE book_series SET avg_rating = (
            SELECT AVG(rating) FROM book_ratings r
                WHERE r.series_id = OLD.series_id ),
            rating_count = rating_count - 1;
        RETURN OLD;
    END IF;
    RETURN NULL;
  END
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
    ELSE IF (TG_OP = 'DELETE') THEN
        UPDATE translation_groups SET avg_rating = (
            SELECT AVG(rating) FROM translator_ratings r
                WHERE r.translator_id = OLD.translator_id );
        RETURN OLD;
    END IF;
    RETURN NULL;
  END
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
    ELSE IF (TG_OP = 'DELETE') THEN
        UPDATE translation_groups SET avg_project_rating = (
            SELECT AVG(r.rating)
		FROM project_ratings r, translation_projects p
                WHERE r.project_id = p.id
		AND r.project_id = OLD.project_id );
        RETURN NEW;
    END IF;
    RETURN NULL;
  END
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_project_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON project_ratings
    EXECUTE PROCEDURE do_update_project_average_rating();

-- update the tags whenever a vote occurs
CREATE FUNCTION do_update_tags() RETURNS trigger AS $$
  BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        r := NEW;
    ELSE IF (TG_OP = 'DELETE') THEN
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
  END
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tags
    AFTER INSERT OR UPDATE OR DELETE ON tag_consensus
    EXECUTE PROCEDURE do_update_tags();