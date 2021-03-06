--
-- Schema for book release tracker
--

DROP SCHEMA books CASCADE;

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

CREATE SCHEMA books;

GRANT ALL ON SCHEMA books TO postgres;
SET search_path TO books,public;

CREATE EXTENSION intarray;

-- schema version (increment whenever it changes)
CREATE TABLE schema_version ( revision int NOT NULL );
INSERT INTO schema_version VALUES (0);

--
-- Books and Authors
--

CREATE TABLE publishers (
    id         serial      PRIMARY KEY,
    name       text        NOT NULL,
    date_added timestamptz NOT NULL DEFAULT now(),
    summary    text
);

CREATE TABLE magazines (
    id           serial      PRIMARY KEY,
    title        text        NOT NULL,
    publisher_id int         NOT NULL REFERENCES publishers,
    language     text        NOT NULL,
    date_added   timestamptz NOT NULL DEFAULT now(),
    demographic  int,
    summary      text
);

CREATE TABLE book_series (
    id           serial      PRIMARY KEY,
    title        text        NOT NULL,
    native_title text        NOT NULL,
    other_titles text[],
    kind         int         NOT NULL DEFAULT 0,
    summary      text,
    vintage      int         NOT NULL, -- year
    date_added   timestamptz NOT NULL,
    last_updated timestamptz NOT NULL,
    finished     boolean     NOT NULL DEFAULT false,
    nsfw         boolean     NOT NULL DEFAULT false,
    avg_rating   real, -- NULL means not rated (as opposed to a zero rating)
    rating_count int         NOT NULL DEFAULT 0,
    demographic  int         NOT NULL,
    magazine_id  int         REFERENCES magazines,
    has_cover    boolean     NOT NULL DEFAULT false
);

-- This table glues book_series and publishers to indicate if a series is
-- officially licensed in countries outside of the original
CREATE TABLE series_licenses (
    id            serial PRIMARY KEY,
    series_id     int    NOT NULL REFERENCES book_series,
    publisher_id  int    NOT NULL REFERENCES publishers,
    country       text   NOT NULL,
    date_licensed date
);

CREATE TABLE authors (
    id          serial  PRIMARY KEY,
    given_name  text    NOT NULL,
    surname     text,
    native_name text,
    aliases     text[],
    picture     boolean NOT NULL DEFAULT false,
    birthday    date,
    bio         text,
    sex         int
);

CREATE TABLE production_credits (
    series_id int NOT NULL REFERENCES book_series,
    author_id int NOT NULL REFERENCES authors,

    -- 0001 : art
    -- 0010 : scenario
    credit    int NOT NULL
);

CREATE VIEW series_credits AS
    SELECT
        s.id series_id,
        a.id author_id,
        a.given_name,
        a.surname,
        pc.credit
    FROM
        book_series        s,
        authors            a,
        production_credits pc
    WHERE s.id = pc.series_id
      AND a.id = pc.author_id
    ORDER BY pc.credit, a.surname;

CREATE TABLE related_series (
    id                serial PRIMARY KEY,
    series_id         int    NOT NULL REFERENCES book_series,
    related_series_id int    NOT NULL REFERENCES book_series,
    relation          int    NOT NULL
);

CREATE VIEW related_series_view AS
    SELECT
        s.id     series_id,
        rs.id    related_id,
        rs.title related_title,
        r.relation
    FROM
        book_series    s,
        book_series    rs,
        related_series r
    WHERE s.id  = r.series_id
      AND rs.id = r.related_series_id;

--
-- Releases and Translators
--

CREATE TABLE translation_groups (
    id               serial PRIMARY KEY,
    name             text   NOT NULL UNIQUE,
    summary          text,
    avg_rating       real,
    rating_count     int    NOT NULL DEFAULT 0,
    avg_release_rate bigint -- seconds
);

CREATE TABLE chapters (
    id           serial      PRIMARY KEY,
    release_date timestamptz NOT NULL DEFAULT 'epoch'::timestamptz,
    series_id    int         NOT NULL REFERENCES book_series,
    num          int         NOT NULL,
    volume       int,
    notes        text
);

CREATE TABLE releases (
    id              serial      PRIMARY KEY,
    series_id       int         NOT NULL REFERENCES book_series,
    language        text        NOT NULL DEFAULT 'en',
    release_date    timestamptz NOT NULL DEFAULT now(),
    notes           text,
    is_last_release boolean     NOT NULL DEFAULT false,
    extra           text,
    permalink       text
);

CREATE TABLE releases_translators (
    id            serial PRIMARY KEY,
    release_id    int    NOT NULL REFERENCES releases,
    translator_id int    NOT NULL REFERENCES translation_groups
);

-- Keeps track of which releases a chapter is included in
-- (may be multiple releases for a given chapter)
CREATE TABLE releases_chapters (
    id         serial PRIMARY KEY,
    release_id int    NOT NULL REFERENCES releases,
    chapter_id int    NOT NULL REFERENCES chapters
);

--CREATE VIEW series_releases AS
--    SELECT
--        r.*,
--        array_agg(ch.volume ORDER BY ch.num) chapter_volumes,
--        array_agg(ch.num    ORDER BY ch.num) chapter_nums,
--        array_agg(t.id      ORDER BY t.id)   translator_ids,
--        array_agg(t.name    ORDER BY t.id)   translator_names
--    FROM
--        releases             r,
--        releases_translators rt,
--        translation_groups   t,
--        releases_chapters    rc,
--        chapters             ch
--    WHERE r.id  = rt.release_id
--      AND t.id  = rt.translator_id
--      AND r.id  = rc.release_id
--      AND ch.id = rc.chapter_id
--    GROUP BY r.*
--    ORDER BY r.release_date DESC;

CREATE VIEW recent_releases AS
    SELECT
        r.id AS release_id,
        s.id AS series_id,
        s.title,
        r.language,
        r.release_date,
        r.is_last_release,
        r.extra,
        r.permalink,
        array_agg(ch.volume)                     chapter_volumes,
        array_agg(ch.num)                        chapter_nums,
        array_agg(DISTINCT t.id ORDER BY t.id) translator_ids,
        array_agg(t.name        ORDER BY t.id) translator_names
    FROM
        releases r,
        book_series s,
        translation_groups t,
        releases_chapters rc,
        releases_translators rt,
        chapters ch
    WHERE r.series_id      = s.id
    AND   rt.release_id    = r.id
    AND   rt.translator_id = t.id
    AND   rc.release_id    = r.id
    AND   rc.chapter_id    = ch.id
    GROUP BY
        r.id,
        s.id,
        s.title,
        r.language,
        r.release_date,
        r.is_last_release,
        r.extra,
        r.permalink
    ORDER BY r.release_date DESC;
--
-- Users
--

CREATE TABLE users (
    id            serial      PRIMARY KEY,
    email         text        NOT NULL,
    name          text        NOT NULL UNIQUE,
    pass          bytea       NOT NULL,
    salt          bytea       NOT NULL,
    rights        int         NOT NULL DEFAULT 0,
    vote_weight   int         NOT NULL DEFAULT 1,
    summary       text,
    register_date timestamptz NOT NULL DEFAULT now(),
    last_active   timestamptz NOT NULL DEFAULT 'epoch'::timestamptz,
    avatar        text, -- avatar filename (sha256 hash)
    active        boolean     NOT NULL DEFAULT false,

    -- a unique hash for this user, used like an API key
    hash          text        NOT NULL, 

    -- deadline for clicking on the activation link
    activate_by   timestamptz NOT NULL DEFAULT now() + '24 hours'
);

CREATE TABLE sessions (
    id          bytea       NOT NULL,
    user_id     int         NOT NULL REFERENCES users,
    expire_date timestamptz NOT NULL DEFAULT 'epoch'::timestamptz
);

CREATE VIEW user_sessions AS
    SELECT
        s.id,
        s.expire_date,
        u.name
    FROM
        users u,
        sessions s
    WHERE s.user_id = u.id;

-- keeps track of which chapters a user has read/owns
CREATE TABLE user_chapters (
    id         serial      PRIMARY KEY,
    user_id    int         NOT NULL REFERENCES users,
    chapter_id int         NOT NULL REFERENCES chapters,
    status     int         NOT NULL,
    date_read  timestamptz NOT NULL DEFAULT now()
);

-- keeps track of which releases a user owns
CREATE TABLE user_releases (
    id         serial      PRIMARY KEY,
    user_id    int         NOT NULL REFERENCES users,
    release_id int         NOT NULL REFERENCES releases,
    status     int         NOT NULL,
    date_owned timestamptz NOT NULL DEFAULT now()
);

-- keeps track of users belonging to translator groups
CREATE TABLE translator_members (
    id            serial PRIMARY KEY,
    user_id       int    NOT NULL REFERENCES users,
    translator_id int    NOT NULL REFERENCES translation_groups
);

--
-- Characters
--

CREATE TABLE characters (
    id          serial  PRIMARY KEY,
    name        text    NOT NULL,
    native_name text    NOT NULL,
    aliases     text[],
    nationality text,
    birthday    date, -- the year is ignored
    sex         int,
    weight      real,
    height      real,
    sizes       text,
    blood_type  int,
    description text,
    picture     boolean NOT NULL DEFAULT false
);

CREATE TABLE characters_roles (
    id           serial PRIMARY KEY,
    character_id int    NOT NULL REFERENCES characters,
    series_id    int    NOT NULL REFERENCES book_series,
    type         int    NOT NULL,
    role         int,
    appearances  int[] --           REFERENCES chapters
);

CREATE VIEW series_characters AS
    SELECT
        c.id,
        c.name,
        c.native_name,
        c.sex,
        c.picture,
        r.series_id,
        r.type,
        r.role
    FROM
        characters c,
        characters_roles r
    WHERE c.id = r.character_id
    ORDER BY r.type;

cREATE TABLE characters_relation_kinds (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE related_characters (
    id                   serial PRIMARY KEY,
    character_id         int    NOT NULL REFERENCES characters,
    related_character_id int    NOT NULL REFERENCES characters,
    relation             int    NOT NULL REFERENCES characters_relation_kinds
);

--
-- User-submitted tags and voting
--

-- book/character_tag_consensus
--   Use a left join to find which tags, if any, a User has voted on
--   for a given Series/Character.

CREATE TABLE book_tag_names (
    id          serial PRIMARY KEY,
    name        text   NOT NULL,
    description text
);

CREATE TABLE book_tags (
    id        serial  PRIMARY KEY,
    series_id int     NOT NULL REFERENCES book_series,
    tag_id    int     NOT NULL REFERENCES book_tag_names,
    spoiler   boolean NOT NULL,
    weight    int     NOT NULL,
    visible   boolean NOT NULL DEFAULT true
);

CREATE TABLE book_tag_consensus (
    id          serial      PRIMARY KEY,
    user_id     int         NOT NULL REFERENCES users,
    book_tag_id int         NOT NULL REFERENCES book_tags,
    vote        int         NOT NULL,
    vote_date   timestamptz NOT NULL DEFAULT now()
);

CREATE VIEW latest_series AS
    SELECT
        s.id,
        s.title,
        s.kind,
        s.vintage,
        s.date_added,
        s.nsfw,
        s.avg_rating,
        s.demographic,
        array_agg(n.name) AS tag_names
    FROM 
        book_series s,
        book_tags t,
        book_tag_names n
    WHERE t.series_id = s.id
      AND t.tag_id    = n.id
      AND t.spoiler   = false
      AND t.visible
    GROUP BY
        s.id,
        s.title,
        s.kind,
        s.vintage,
        s.date_added,
        s.nsfw,
        s.avg_rating,
        s.demographic
    ORDER BY s.date_added DESC;

CREATE VIEW series_page AS
    SELECT
        s.id,
        s.title,
        s.native_title,
        s.other_titles,
        s.kind,
        s.summary,
        s.vintage,
        s.date_added,
        s.last_updated,
        s.finished,
        s.nsfw,
        s.avg_rating,
        s.rating_count,
        s.demographic,
        COALESCE(m.magazine_id, 0)           magazine_id,
        COALESCE(m.magazine_title, '(none)') magazine_title,
        COALESCE(m.publisher_id, 0)          publisher_id,
        COALESCE(m.publisher_name, '(none)') publisher_name,
        s.has_cover
    FROM
        book_series s
        LEFT JOIN (
            SELECT
                ms.id    magazine_id,
                ms.title magazine_title,
                p.id     publisher_id,
                p.name   publisher_name
            FROM
                magazines  ms,
                publishers p
            WHERE p.id = ms.publisher_id
        ) m USING ( magazine_id );

CREATE VIEW series_tags AS
    SELECT
        s.id series_id,
        btn.name,
        bt.spoiler,
        bt.weight
    FROM
        book_series s,
        book_tags bt,
        book_tag_names btn
    WHERE s.id   = bt.series_id
      AND btn.id = bt.tag_id
      AND bt.visible
    ORDER BY bt.weight DESC, btn.name;


CREATE TABLE character_tag_names (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE character_tags (
    id           serial  PRIMARY KEY,
    character_id int     NOT NULL REFERENCES characters,
    tag_id       int     NOT NULL REFERENCES character_tag_names,
    spoiler      boolean NOT NULL,
    weight       int     NOT NULL,
    visible      boolean NOT NULL DEFAULT true
);

CREATE TABLE character_tag_consensus (
    id               serial      PRIMARY KEY,
    user_id          int         NOT NULL REFERENCES users,
    character_tag_id int         NOT NULL REFERENCES character_tags,
    vote             int         NOT NULL,
    vote_date        timestamptz NOT NULL
);

--
-- Favorites
--

CREATE TABLE favorite_authors (
    id        serial PRIMARY KEY,
    user_id   int    NOT NULL REFERENCES users,
    author_id int    NOT NULL REFERENCES authors
);

CREATE TABLE favorite_series (
    id        serial PRIMARY KEY,
    user_id   int    NOT NULL REFERENCES users,
    series_id int    NOT NULL REFERENCES book_series
);

CREATE TABLE favorite_translators (
    id            serial PRIMARY KEY,
    user_id       int    NOT NULL REFERENCES users,
    translator_id int    NOT NULL REFERENCES translation_groups
);

CREATE TABLE favorite_magazines (
    id          serial PRIMARY KEY,
    user_id     int    NOT NULL REFERENCES users,
    magazine_id int    NOT NULL REFERENCES magazines
);

CREATE TABLE favorite_book_tags (
    id      serial PRIMARY KEY,
    user_id int    NOT NULL REFERENCES users,
    tag_id  int    NOT NULL REFERENCES book_tag_names
);

CREATE TABLE favorite_character_tags (
    id      serial PRIMARY KEY,
    user_id int    NOT NULL REFERENCES users,
    tag_id  int    NOT NULL REFERENCES character_tag_names
);

--
-- Filters
--

CREATE TABLE filtered_groups (
    id       serial PRIMARY KEY,
    user_id  int    NOT NULL REFERENCES users,
    group_id int    NOT NULL REFERENCES translation_groups
);

CREATE TABLE filtered_languages (
    id       serial PRIMARY KEY,
    user_id  int    NOT NULL REFERENCES users,
    language text   NOT NULL
);

CREATE TABLE filtered_book_tags (
    id      serial PRIMARY KEY,
    user_id int    NOT NULL REFERENCES users,
    tag_id  int    NOT NULL REFERENCES book_tag_names
);

CREATE TABLE filtered_character_tags (
    id      serial PRIMARY KEY,
    user_id int    NOT NULL REFERENCES users,
    tag_id  int    NOT NULL REFERENCES character_tag_names
);

--
-- Ratings and Reviews
--

CREATE TABLE book_ratings (
    id        serial      PRIMARY KEY,
    user_id   int         NOT NULL REFERENCES users,
    series_id int         NOT NULL REFERENCES book_series,
    rating    int         NOT NULL,
    review    text,
    rate_date timestamptz NOT NULL
);

CREATE VIEW series_book_ratings AS
    SELECT
        r.id,
        u.id user_id,
        u.name,
        s.id series_id,
        r.rating,
        r.review,
        r.rate_date
    FROM
        books.book_ratings r,
        books.users        u,
        books.book_series  s
    WHERE r.series_id = s.id
      AND r.user_id   = u.id
      AND r.review    IS NOT NULL
    ORDER BY r.rate_date DESC;

CREATE TABLE translator_ratings (
    id            serial      PRIMARY KEY,
    user_id       int         NOT NULL REFERENCES users,
    translator_id int         NOT NULL REFERENCES translation_groups,
    rating        int         NOT NULL,
    review        text,
    rate_date     timestamptz NOT NULL
);

--
-- Entities that may be associated with any number of URLs
--

-- Website, Twitter, Blog, Facebook, etc.
CREATE TABLE link_kinds (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE publisher_links (
    id           serial PRIMARY KEY,
    publisher_id int    NOT NULL REFERENCES publishers,
    link_kind    int    NOT NULL REFERENCES link_kinds,
    url          text   NOT NULL
);

CREATE TABLE magazine_links (
    id          serial PRIMARY KEY,
    magazine_id int    NOT NULL REFERENCES magazines,
    link_kind   int    NOT NULL REFERENCES link_kinds,
    url         text   NOT NULL
);
CREATE TABLE author_links (
    id        serial PRIMARY KEY,
    author_id int    NOT NULL REFERENCES authors,
    link_kind int    NOT NULL REFERENCES link_kinds,
    url       text   NOT NULL
);

CREATE TABLE translator_links (
    id            serial PRIMARY KEY,
    translator_id int    NOT NULL REFERENCES translation_groups,
    link_kind     int    NOT NULL REFERENCES link_kinds,
    url           text   NOT NULL
);

--
-- Site news
--

CREATE TABLE news_categories (
    id   serial PRIMARY KEY,
    name text   NOT NULL
);

CREATE TABLE news_posts (
    id          serial      PRIMARY KEY,
    user_id     int         NOT NULL REFERENCES users,
    category_id int         NOT NULL REFERENCES news_categories,
    date_posted timestamptz NOT NULL DEFAULT now(),
    title       text        NOT NULL,
    body        text        NOT NULL
);

CREATE VIEW latest_news AS
    SELECT
        p.id AS post_id,
        u.id AS user_id,
        u.name AS user_name,
        c.name AS category,
        p.date_posted,
        p.title,
        p.body
    FROM
        news_posts p,
        users u,
        news_categories c
    WHERE c.id = p.category_id
      AND u.id = p.user_id
    ORDER BY p.date_posted DESC;

--
-- Feeds
--

CREATE TABLE feeds (
    id           serial      PRIMARY KEY,
    input_kind   int         NOT NULL,
    output_kind  int         NOT NULL,
    ref          text        NOT NULL UNIQUE, -- A random string of bytes that identifies this feed (don't use the id)
    include      int[]       NOT NULL,
    exclude      int[]       NOT NULL DEFAULT '{}',
    creator      int         REFERENCES users,
    title        text        NOT NULL,
    description  text        NOT NULL DEFAULT '',
    date_created timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE feed_permissions (
    id         serial      PRIMARY KEY,
    feed_id    int         NOT NULL REFERENCES feeds,
    user_id    int         NOT NULL REFERENCES users,
    action     int         NOT NULL, -- allow, disallow, ...
    date_given timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE feed_subscriptions (
    id          serial      PRIMARY KEY,
    feed_id     int         NOT NULL REFERENCES feeds,
    user_id     int         NOT NULL REFERENCES users,
    private     boolean     NOT NULL DEFAULT false,
    date_subbed timestamptz NOT NULL DEFAULT now()
);

--
-- Triggers and rules
--

-- update the average rating whenever a rating occurs
-- TODO: ratings may have to be cached and updates executed in batch somehow eventually
CREATE FUNCTION do_update_book_average_rating() RETURNS trigger AS $$
    BEGIN
        CASE TG_OP
        WHEN 'INSERT', 'UPDATE' THEN
            UPDATE books.book_series
                SET avg_rating = (
                    -- NOTE: watch out for potential off-by-one error here
                    -- (the NEW record might not be included in this SELECT
                    -- though it should be ok since the trigger is AFTER)
                    SELECT AVG(rating)
                        FROM book_ratings r
                        WHERE r.series_id = NEW.series_id
                ),
                rating_count = rating_count + 1
                WHERE id = NEW.series_id;
            RETURN NEW;
        WHEN 'DELETE' THEN
            UPDATE books.book_series
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM book_ratings r
                        WHERE r.series_id = OLD.series_id
                ),
                rating_count = rating_count - 1
                WHERE id = OLD.series_id;
            RETURN OLD;
        END CASE;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_book_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON books.book_ratings FOR EACH ROW
    EXECUTE PROCEDURE do_update_book_average_rating();

CREATE FUNCTION do_update_translator_average_rating() RETURNS trigger AS $$
    BEGIN
        CASE TG_OP
        WHEN 'INSERT', 'UPDATE' THEN
            UPDATE books.translation_groups
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM translator_ratings r
                        WHERE r.translator_id = NEW.translator_id
                ),
                rating_count = rating_count + 1
                WHERE id = NEW.translator_id;
            RETURN NEW;
        WHEN 'DELETE' THEN
            UPDATE books.translation_groups
                SET avg_rating = (
                    SELECT AVG(rating)
                        FROM translator_ratings r
                        WHERE r.translator_id = OLD.translator_id
                ),
                rating_count = rating_count - 1
                WHERE id = NEW.translator_id;
            RETURN OLD;
        END CASE;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_translator_average_rating
    AFTER INSERT OR UPDATE OR DELETE ON books.translator_ratings FOR EACH ROW
    EXECUTE PROCEDURE do_update_translator_average_rating();

-- update the tags whenever a vote occurs
CREATE FUNCTION do_update_book_tags() RETURNS trigger AS $$
    DECLARE
        rec        RECORD;
        new_weight int;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            rec := NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            rec := OLD;
        END IF;

        -- the cutoff should probably be 0 (which means a perfectly disputed
        -- vote with zero agreement) but we'll give it a buffer of 5
        -- before it's actually deleted, in case somebody wants to rescue it.
        -- Keep in mind votes are either positive or negative, never zero.

        -- On second thought, maybe we should keep the tags around and just not
        -- show them (but they can always be recovered if necessary)
        SELECT INTO new_weight
            SUM(vote)
            FROM books.book_tag_consensus c
            WHERE c.book_tag_id = rec.book_tag_id;

        -- TODO: set up hiding disagreed upon tags as a batch job instead of
        -- hiding immediately
        UPDATE books.book_tags
        SET    weight = new_weight
        WHERE  id = rec.book_tag_id;

        RETURN rec;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_book_tags
    AFTER INSERT OR UPDATE OR DELETE ON books.book_tag_consensus FOR EACH ROW
    EXECUTE PROCEDURE do_update_book_tags();

CREATE FUNCTION do_update_character_tags() RETURNS trigger AS $$
    DECLARE
        rec        RECORD;
        --new_weight int;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            rec := NEW;
        ELSIF (TG_OP = 'DELETE') THEN
            rec := OLD;
        END IF;

        UPDATE books.character_tags
            SET weight = (
                SELECT avg(vote)
                    FROM character_tag_consensus c
                    WHERE c.character_tag_id = rec.character_tag_id
                )
            WHERE id = rec.character_tag_id;

        RETURN rec;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_character_tags
    AFTER INSERT OR UPDATE OR DELETE ON books.character_tag_consensus FOR EACH ROW
    EXECUTE PROCEDURE do_update_character_tags();

-- update the chapters a user owns when he gets a release
CREATE FUNCTION do_update_user_chapters() RETURNS trigger AS $$
    BEGIN
        INSERT INTO books.user_chapters (user_id, chapter_id, status)
            SELECT NEW.user_id, c.id, NEW.status
                FROM chapters c, releases_chapters r
                WHERE r.chapter_id = c.id
                AND r.release_id = NEW.release_id;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE RULE user_chapters_ignore_duplicates_on_insert AS
    ON INSERT TO books.user_chapters
    WHERE (EXISTS (
        SELECT 1
        FROM books.user_chapters
        WHERE user_chapters.chapter_id = NEW.chapter_id
    ))
    DO INSTEAD NOTHING;

CREATE TRIGGER update_user_chapters
    AFTER INSERT ON books.user_releases FOR EACH ROW
    EXECUTE PROCEDURE do_update_user_chapters();

-- update the object of a series relation
CREATE FUNCTION do_update_series_relations() RETURNS trigger AS $$
    DECLARE
        related_relation int;
    BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            CASE NEW.relation
            WHEN 0 THEN
                related_relation := 5;
            WHEN 1 THEN
                related_relation := 1;
            WHEN 5 THEN
                related_relation := 0;
            WHEN 3 THEN
                related_relation := 2;
            WHEN 2 THEN
                related_relation := 3;
            WHEN 4 THEN
                related_relation := 0;
            WHEN 6 THEN
                related_relation := 6;
            ELSE
                RAISE EXCEPTION 'Unknown series relation enum value: %', NEW.relation
                    USING HINT = 'Function do_update_series_relations() may need to be updated';
            END CASE;
        ELSE
            DELETE FROM books.related_series
                WHERE series_id = OLD.related_series_id
                AND related_series_id = OLD.series_id;
                RETURN OLD;
        END IF;

        CASE TG_OP
        WHEN 'INSERT' THEN
            INSERT INTO books.related_series (series_id, related_series_id, relation)
                VALUES (NEW.related_series_id, NEW.series_id, related_relation);
        WHEN 'UPDATE' THEN
            UPDATE books.related_series
                SET relation = related_relation
                WHERE series_id = NEW.related_series_id
                AND related_series_id = NEW.series_id;
        END CASE;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE RULE series_relations_ignore_duplicates_on_insert AS
    ON INSERT TO books.related_series
    WHERE (EXISTS (
        SELECT 1
            FROM books.related_series
            WHERE series_id = NEW.series_id
            AND related_series_id = NEW.related_series_id
    ))
    DO INSTEAD NOTHING;

CREATE TRIGGER update_series_relations
    AFTER INSERT OR UPDATE OR DELETE ON books.related_series FOR EACH ROW
    EXECUTE PROCEDURE do_update_series_relations();

END;
