BEGIN;

SET search_path TO books,public;

INSERT INTO users VALUES
	( DEFAULT, 'moshee@displaynone.us', 'moshee', <%= bytea %>, <%= bytea %>, 30, 10, 'ザー・会長', <%= tstz %>, 'now'::timestamptz, true, true),
	( DEFAULT, 'deu@pomf.eu', 'deu', <%= bytea %>, <%= bytea %>, 30, 10, 'hi my name is deu and I have bad taste', <%= tstz %>, 'now'::timestamptz, true, true),
	( DEFAULT, 'franz@gj-bu.com', 'franz', <%= bytea %>, <%= bytea %>, 30, 10, 'constantly eating foods', <%= tstz %>, 'now'::timestamptz, true, true),
	<%= rec(100) { ['DEFAULT', email, text(/[:first_name:]\d{0,4}/.gen), bytea, bytea, (if rand > 0.05 then 1 else 0 end), rand(0..10), (null or longstring), tstz, tstz, bool, bool(0.9)] } %>

INSERT INTO publishers VALUES
	( DEFAULT, 'Kodansha', <%= tstz %>, NULL ),
	( DEFAULT, 'Shueisha', <%= tstz %>, NULL ),
	( DEFAULT, 'Hakusensha', <%= tstz %>, 'they do some pretty good stuff' ),
	( DEFAULT, 'Houbunsha', <%= tstz %>, 'Manga Time stuff is good' ),
	( DEFAULT, 'Media Factory', <%= tstz %>, 'denki-gai is good, comic flapper is good' ),
	<%= rec(50) { ['DEFAULT', sample(:companies), tstz, string] } %>

INSERT INTO magazines VALUES
	( DEFAULT, 'Bessatsu Shounen Magazine', 1, 'ja', <%= tstz %>, 0, 'eotens' ),
	( DEFAULT, 'Weekly Young Jump', 2, 'ja', <%= tstz %>, 2, 'johj' ),
	( DEFAULT, 'Young Animal', 3, 'ja', <%= tstz %>, 2, 'KAAAAAAIIIIIIIII' ),
	( DEFAULT, 'Manga Time Kirara Carat', 4, 'ja', <%= tstz %>, 2, 'hidamari yes' ),
	( DEFAULT, 'Comic Flapper', 5, 'ja', <%= tstz %>, 2, 'chocolate panic' ),
	<%= rec(50) { ['DEFAULT', sample(:products), rand(1..55), lang('ja', 0.99), tstz, rand(5), (null or string)] } %>

INSERT INTO book_series VALUES
    ( DEFAULT, 'From the New World', '新世界より', NULL, 'Comic', 'so many scifi tropes', 2012, <%= tstz %>, <%= tstz %>, false, true, NULL, 0, 0, 1 ),
	( DEFAULT, 'The Eotena Onslaught', '進撃の巨人', NULL, 'Comic', 'eotens', 2009, <%= tstz %>, <%= tstz %>, false, false, NULL, 0, 0, 1 ),
	( DEFAULT, 'Flying Witch', 'ふらいんぐうぃっち', NULL, 'Comic', 'it''s like yotsuba with magic', 2012, <%= tstz %>, <%= tstz %>, false, false, NULL, 0, 0, 1 ),
	( DEFAULT, 'Terra ForMars', 'テラフォーマーズ', NULL, 'Comic', 'johj', 2011, <%= tstz %>, <%= tstz %>, false, true, NULL, 0, 2, 2 ),
	( DEFAULT, 'Suicide Island', '自殺島', NULL, 'Comic', 'goats', 2008, <%= tstz %>, <%= tstz %>, false, true, NULL, 0, 2, 3 ),
	( DEFAULT, 'Electric Town Bookstore', 'デンキ街の本屋さん', NULL, 'Comic', 'sensei-san best', 2011, <%= tstz %>, <%= tstz %>, false, false, NULL, 0, 2, 5 ),
	( DEFAULT, 'Girl Meets Bear', 'くまみこ', NULL, 'Comic', 'I''m not really sure myself', 2013, <%= tstz %>, <%= tstz %>, false, false, NULL, 0, 2, 5 ),
	( DEFAULT, 'Sunshine Sketch', 'ひだまりスケッチ', NULL, 'Comic', 'X''___________''X)', 2004, <%= tstz %>, <%= tstz %>, false, false, NULL, 0, 2, 4 ),
	( DEFAULT, 'Let''s have a meal together!', 'ごはん しよ！', NULL, 'Comic', 'food', 2012, <%= tstz %>, <%= tstz %>, false, false, NULL, 0, 2, 5 ),
	<%= rec(150) { ['DEFAULT', rand(2), longstring(4), rand(1950..2013), tstz, tstz, bool(0.3), bool(0.1), nil, 0, rand(5), rand(1..55)] } %>

INSERT INTO authors
	( given_name, surname, native_name, sex )
	VALUES
	( 'Toru', 'Oikawa', '及川 徹', 1 ),
	( 'Yusuke', 'Kishi', '貴志 祐介', 0 ),
	( 'Hajime', 'Isayama', '諫山 創', 0 ),
	( 'Chihiro', 'Ishizuka', '石塚 千尋', NULL ),
	( 'Yu', 'Sasuga', '貴家 悠', 0 ),
	( 'Kenichi', 'Tachibana', '橘 賢一', 0 ),
	( 'Koji', 'Mori', '森 恒二', 0 ),
	( 'Asato', 'Mizu', '水 あさと', 0 ),
	( 'Masume', 'Yoshimoto', '吉元 ますめ', NULL ),
	( 'Ume', 'Aoki', '蒼樹 うめ', 1 ),
    ( 'Sei', 'Takano', '高野 聖', 0 );

INSERT INTO authors VALUES
<%= rec(50) { ['DEFAULT', firstname, (null(0.1) or lastname), (null(0.05) or cjk_name), nil, bool, (null or date), (null or string), (null(0.2) or gender)] } %>

INSERT INTO production_credits VALUES
	( 1, 1, 1 ),
	( 1, 2, 2 ),
	( 2, 3, 3 ),
	( 3, 4, 3 ),
	( 4, 5, 2 ),
	( 4, 6, 1 ),
	( 5, 7, 3 ),
	( 6, 8, 3 ),
	( 7, 9, 3 ),
	( 8, 10, 3 ),
	( 9, 11, 3 ),
    <%= rec(150, repeat_chance=0.4) { |n, repeating| [n+9, rand(1..61), (if repeating then [1, 2].sample else 3 end)] } %>

INSERT INTO related_series VALUES
    <%= rec(60) { ['DEFAULT', rand(10..76), rand(77..159), rand(6)] } %>

INSERT INTO translation_groups VALUES
	( DEFAULT, 'display: none;', 'that''s me', NULL, 0, 0 ),
	( DEFAULT, 'Mixini Studios', 'slow', NULL, 0, 0 ),
	( DEFAULT, 'NEO ZEED Marine Stronghold', ':E', NULL, 0, 0 ),
	( DEFAULT, 'Duwang', 'A feeling so complicated.', NULL, 0, 0 ),
    <%= rec(50) { ['DEFAULT', sample(:companies), longstring, nil, 0, 0] } %>

INSERT INTO translation_projects
	( series_id )
	VALUES
	(1), (2), (3), (4), (5), (6), (9),
    <%= rec(90) { |n| [n+9] } %> -- we're not doing all of them here because I wanna see series that haven't been picked up

INSERT INTO translation_project_groups
	( project_id, translator_id )
	VALUES
	( 1, 1 ),
	( 2, 4 ),
	( 3, 1 ),
	( 3, 2 ),
	( 3, 3 ),
	( 4, 1 ),
	( 5, 4 ),
	( 6, 1 ),
	( 7, 1 ),
    <%= rec(90) { |n| [n+7, rand(5..54)] } %>

--==--==--==--==--==--==--==--==--==--

-- real world chapters

INSERT INTO chapters
	( series_id, num )
	VALUES
	( 1, 1 ), ( 1, 2 ), ( 1, 3 ), ( 1, 4 ), ( 1, 5 ), ( 1, 6 ), ( 1, 7 ), ( 1, 8 ), ( 1, 9 ), ( 1, 10 ), ( 1, 11 ), ( 1, 12 ), ( 1, 13 ), ( 1, 14 ), ( 1, 15 ), ( 1, 16 ), ( 1, 17 ),
	( 2, 1 ), ( 2, 2 ), ( 2, 3 ), ( 2, 4 ), ( 2, 5 ), ( 2, 6 ), ( 2, 7 ), ( 2, 8 ), ( 2, 9 ), ( 2, 10 ), ( 2, 11 ), ( 2, 12 ), ( 2, 13 ), ( 2, 14 ), ( 2, 15 ), ( 2, 16 ), ( 2, 17 ), ( 2, 18 ), ( 2, 19 ), ( 2, 20 ), ( 2, 21 ), ( 2, 22 ), ( 2, 23 ), ( 2, 24 ), ( 2, 25 ), ( 2, 26 ), ( 2, 27 ), ( 2, 28 ), ( 2, 29 ), ( 2, 30 ), ( 2, 31 ), ( 2, 32 ), ( 2, 33 ), ( 2, 34 ), ( 2, 35 ), ( 2, 36 ), ( 2, 37 ), ( 2, 38 ), ( 2, 39 ), ( 2, 40 ), ( 2, 41 ), ( 2, 42 ), ( 2, 43 ), ( 2, 44 ), ( 2, 45 ), ( 2, 46 ), ( 2, 47 ), ( 2, 48 ), ( 2, 49 ),
	( 3, 1 ), ( 3, 2 ), ( 3, 3 ), ( 3, 4 ), ( 3, 5 ), ( 3, 6 ), ( 3, 7 ), ( 3, 8 ),
	( 4, 1 ), ( 4, 2 ), ( 4, 3 ), ( 4, 4 ), ( 4, 5 ), ( 4, 6 ), ( 4, 7 ), ( 4, 8 ), ( 4, 9 ), ( 4, 10 ), ( 4, 11 ), ( 4, 12 ), ( 4, 13 ), ( 4, 14 ), ( 4, 15 ), ( 4, 16 ), ( 4, 17 ), ( 4, 18 ), ( 4, 19 ), ( 4, 20 ), ( 4, 21 ), ( 4, 22 ), ( 4, 23 ), ( 4, 24 ), ( 4, 25 ), ( 4, 26 ), ( 4, 27 ), ( 4, 28 ), ( 4, 29 ), ( 4, 30 ), ( 4, 31 ), ( 4, 32 ), ( 4, 33 ), ( 4, 34 ), ( 4, 35 ), ( 4, 36 ), ( 4, 37 ), ( 4, 38 ), ( 4, 39 ), ( 4, 40 ), ( 4, 41 ), ( 4, 42 ), ( 4, 43 ), ( 4, 44 ), ( 4, 45 ), ( 4, 46 ), ( 4, 47 ), ( 4, 48 ), ( 4, 49 ), ( 4, 50 ), ( 4, 51 ), ( 4, 52 ), ( 4, 53 ), ( 4, 54 ), ( 4, 55 ), ( 4, 56 ), ( 4, 57 ), ( 4, 58 ), ( 4, 59 ), ( 4, 60 ), ( 4, 61 ), ( 4, 62 ), ( 4, 63 ),
	( 5, 1 ), ( 5, 2 ), ( 5, 3 ), ( 5, 4 ), ( 5, 5 ), ( 5, 6 ), ( 5, 7 ), ( 5, 8 ), ( 5, 9 ), ( 5, 10 ), ( 5, 11 ), ( 5, 12 ), ( 5, 13 ), ( 5, 14 ), ( 5, 15 ), ( 5, 16 ), ( 5, 17 ), ( 5, 18 ), ( 5, 19 ), ( 5, 20 ), ( 5, 21 ), ( 5, 22 ), ( 5, 23 ), ( 5, 24 ), ( 5, 25 ), ( 5, 26 ), ( 5, 27 ), ( 5, 28 ), ( 5, 29 ), ( 5, 30 ), ( 5, 31 ), ( 5, 32 ), ( 5, 33 ), ( 5, 34 ), ( 5, 35 ), ( 5, 36 ), ( 5, 37 ), ( 5, 38 ), ( 5, 39 ), ( 5, 40 ), ( 5, 41 ), ( 5, 42 ), ( 5, 43 ), ( 5, 44 ), ( 5, 45 ), ( 5, 46 ), ( 5, 47 ), ( 5, 48 ), ( 5, 49 ), ( 5, 50 ), ( 5, 51 ), ( 5, 52 ), ( 5, 53 ), ( 5, 54 ), ( 5, 55 ), ( 5, 56 ), ( 5, 57 ), ( 5, 58 ), ( 5, 59 ), ( 5, 60 ), ( 5, 61 ), ( 5, 62 ), ( 5, 63 ), ( 5, 64 ), ( 5, 65 ), ( 5, 66 ), ( 5, 67 ), ( 5, 68 ), ( 5, 69 ), ( 5, 70 ), ( 5, 71 ), ( 5, 72 ), ( 5, 73 ), ( 5, 74 ), ( 5, 75 ), ( 5, 76 ), ( 5, 77 ), ( 5, 78 ), ( 5, 79 ), ( 5, 80 ), ( 5, 81 ), ( 5, 82 ), ( 5, 83 ), ( 5, 84 ), ( 5, 85 ), ( 5, 86 ), ( 5, 87 ), ( 5, 88 ), ( 5, 89 ), ( 5, 90 ), ( 5, 91 ), ( 5, 92 ), ( 5, 93 ), ( 5, 94 ), ( 5, 95 ), ( 5, 96 ), ( 5, 97 ), ( 5, 98 ), ( 5, 99 ), ( 5, 100 ), ( 5, 101 ), ( 5, 102 ), ( 5, 103 ), ( 5, 104 ), ( 5, 105 ), ( 5, 106 ), ( 5, 107 ), ( 5, 108 ), ( 5, 109 ), ( 5, 110 ), ( 5, 111 ), ( 5, 112 ), ( 5, 113 ), ( 5, 114 ), ( 5, 115 ), ( 5, 116 ), ( 5, 117 ), ( 5, 118 ), ( 5, 119 ), ( 5, 120 ),
	( 6, 1 ), ( 6, 2 ), ( 6, 3 ), ( 6, 4 ), ( 6, 5 ), ( 6, 6 ), ( 6, 7 ), ( 6, 8 ), ( 6, 9 ), ( 6, 10 ), ( 6, 11 ), ( 6, 12 ), ( 6, 13 ), ( 6, 14 ), ( 6, 15 ), ( 6, 16 ), ( 6, 17 ), ( 6, 18 ), ( 6, 19 ), ( 6, 20 ), ( 6, 21 ), ( 6, 22 ), ( 6, 23 ), ( 6, 24 ), ( 6, 25 ), ( 6, 26 ), ( 6, 27 ), ( 6, 28 ), ( 6, 29 ), ( 6, 30 ),
	( 7, 1 ), ( 7, 2 ), ( 7, 3 ), ( 7, 4 ), ( 7, 5 ), ( 7, 6 ),
    ( 9, 1 ), ( 9, 2 ), ( 9, 3 ), ( 9, 4 ), ( 9, 5 ), ( 9, 6 ), ( 9, 7 ), ( 9, 8 ), ( 9, 9 ), ( 9, 10 );


-- random chapters

INSERT INTO chapters VALUES
<%= rec(500) { ['DEFAULT', tstz, rand(10..159), rand(1..200), (null or rand(30)), (null(0.99) or string)] } %>

--==--==--==--==--==--==--==--==--==--

-- real-world data releases+chapters

INSERT INTO releases VALUES
<%= rec(50) { ['DEFAULT', rand(1..9), rand(1..4), rand(1..7), lang('en', 0.9), tstz, (null(0.99) or string), bool(0.01), (null or rand(1..50)), (null(0.8) or rand(1))] } %>

INSERT INTO chapters_releases VALUES
<%= rec(200) { ['DEFAULT', rand(1..295), rand(1..50)] } %>

-- random data releases+chapters

INSERT INTO releases VALUES
<%= rec(300) { ['DEFAULT', rand(10..159), rand(5..54), rand(8..97), lang('en', 0.9), tstz, (null(0.99) or string), bool(0.01), (null or rand(1..50)), (null(0.8) or rand(1))] } %>

INSERT INTO chapters_releases VALUES
<%= rec(200) { ['DEFAULT', rand(296..795), rand(51..350)] } %>

--==--==--==--==--==--==--==--==--==--

INSERT INTO user_chapters VALUES
<%= rec(100) { ['DEFAULT', rand(1..103), rand(1..295), rand(2), tstz] } %>

INSERT INTO user_releases VALUES
<%= rec(30) { ['DEFAULT', rand(1..103), rand(1..50), rand(2), tstz] } %>

INSERT INTO translator_members
	( user_id, translator_id )
	VALUES
    ( 1, 1 ),
    ( 2, 4 ),
    ( 3, 3 ),
    <%= rec(20) { [rand(1..103), rand(1..54)] } %>

INSERT INTO characters VALUES
<%= rec(200) { ['DEFAULT', name, cjk_name, nil, (null or country), (null or date), (null or gender), (null or rand(1..100)), (null or rand(1..500)), (null(0.9) or /\d{2}-\d{2}-\d{2}/.gen), (null or rand(3)), (null or string), bool] } %>

INSERT INTO characters_roles VALUES
<%= rec(200) { |n| ['DEFAULT', n, rand(1..159), rand(3), (nil or rand(9)), nil] } %>

INSERT INTO characters_relation_kinds
    ( name )
    VALUES
    ( 'Younger sibling' ),
    ( 'Older sibling' ),
    ( 'Parent' ),
    ( 'Teacher' ),
    ( 'Opponent' ),
    ( 'Friend' ),
    ( 'Alternate self' ),
    ( 'Teammate' );

INSERT INTO related_characters VALUES
<%= rec(100) { ['DEFAULT', rand(1..100), rand(101..200), rand(1..8)] } %>

INSERT INTO book_tag_names VALUES
<%= rec($files[:colors].size) { |n| ['DEFAULT', text($files[:colors][n-1])] } %>

INSERT INTO book_tags VALUES
<%= rec(500) { ['DEFAULT', rand(1..159), rand(1..($files[:colors].size)), bool(0.05), rand] } %>

INSERT INTO book_tag_consensus VALUES
<%= rec(500) { ['DEFAULT', rand(1..103), rand(1..500), rand(-5..10), tstz] } %>

INSERT INTO character_tag_names VALUES
<%= rec($files[:colors].size) { |n| ['DEFAULT', text($files[:colors][n-1])] } %>

INSERT INTO character_tags VALUES
<%= rec(500) { ['DEFAULT', rand(1..200), rand(1..($files[:colors].size)), bool(0.05), rand] } %>

INSERT INTO character_tag_consensus VALUES
<%= rec(500) { ['DEFAULT', rand(1..103), rand(1..500), rand(-5..10), tstz] } %>

<% sizes = { authors: 61, series: 159, translators: 54, magazines: 55, book_tags: $files[:colors].size, character_tags: $files[:colors].size } %>

<% sizes.each do |k, v| %>
INSERT INTO favorite_<%= k %> VALUES
<%= rec(300) { ['DEFAULT', rand(1..103), rand(1..v)] } %>
<% end %>

<% sizes[:publishers] = 55 %>

INSERT INTO filtered_groups (user_id, group_id) VALUES
<%= rec(50) { [rand(1..103), rand(1..54)] } %>

INSERT INTO filtered_languages (user_id, language) VALUES
<%= rec(50) { [rand(1..103), lang] } %>

INSERT INTO filtered_book_tags (user_id, tag_id) VALUES
<%= rec(50) { [rand(1..103), rand(1..sizes[:book_tags])] } %>

INSERT INTO filtered_character_tags (user_id, tag_id) VALUES
<%= rec(50) { [rand(1..103), rand(1..sizes[:character_tags])] } %>

INSERT INTO book_ratings VALUES
<%= rec(1000) { ['DEFAULT', rand(1..103), rand(1..159), rand(1..5), (null(0.99) or longstring), tstz] } %>

INSERT INTO translator_ratings VALUES
<%= rec(200) { ['DEFAULT', rand(1..103), rand(1..54), rand(1..5), (null(0.99) or longstring), tstz] } %>

INSERT INTO link_kinds (name) VALUES
    ( 'Twitter' ),
    ( 'Blog' ),
    ( 'Facebook' ),
    ( 'Website' ),
    ( 'Fanpage' ),
    ( 'Pixiv' ),
    ( 'Flickr' ),
    ( 'Other' ),
    ( 'Profile' );

INSERT INTO publisher_links VALUES
<%= rec(80) { ['DEFAULT', rand(1..sizes[:publishers]), rand(1..9), url] } %>

INSERT INTO magazine_links VALUES
<%= rec(80) { ['DEFAULT', rand(1..sizes[:magazines]), rand(1..9), url] } %>

INSERT INTO author_links VALUES
<%= rec(80) { ['DEFAULT', rand(1..sizes[:authors]), rand(1..9), url] } %>

INSERT INTO translator_links VALUES
<%= rec(80) { ['DEFAULT', rand(1..sizes[:translators]), rand(1..9), url] } %>

INSERT INTO news_categories (name) VALUES
    ( 'Site update' ),
    ( 'Announcement' ),
    ( 'Unsolicited blogging' ),
    ( 'Poll' );

INSERT INTO news_posts VALUES
<%= rec(20) { ['DEFAULT', rand(1..3), rand(1..4), tstz, string, longstring] } %>

END;
