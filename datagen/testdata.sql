INSERT INTO users
	( name, summary )
	VALUES
	( 'moshee', 'ザー・会長' ),
	( 'deu', 'hi my name is deu and I have bad taste' ),
	( 'franz', 'I m constantly eating foods' );

INSERT INTO publishers
	( name, summary )
	VALUES
	( 'Kodansha', NULL ),
	( 'Shueisha', NULL ),
	( 'Hakusensha', 'they do some pretty good stuff' ),
	( 'Houbunsha', 'Manga Time stuff is good' ),
	( 'Media Factory', 'denki-gai is good, comic flapper is good' );

INSERT INTO magazines
	( title, publisher, summary )
	VALUES
	( 'Bessatsu Shounen Magazine', 1, 'eotens' ),
	( 'Weekly Young Jump', 2, 'johj' ),
	( 'Young Animal', 3, 'KAAAAAAIIIIIIIII' ),
	( 'Manga Time Kirara Carat', 4, 'hidamari yes' ),
	( 'Comic Flapper', 5, 'chocolate panic' );

INSERT INTO book_series
	( kind, title, summary, vintage, nsfw, demographic, magazine_id )
	VALUES
	( 'Comic', 'From the New World', 'so many scifi tropes', 2012, true, 'Shounen', 1 ),
	( 'Comic', 'The Eotena Onslaught', 'eotens', 2009, false, 'Shounen', 1 ),
	( 'Comic', 'Flying Witch', 'it''s like yotsuba with magic', 2012, false, 'Shounen', 1 ),
	( 'Comic', 'Terra ForMars', 'johj', 2011, true, 'Seinen', 2 ),
	( 'Comic', 'Suicide Island', 'goats', 2008, true, 'Seinen', 3 ),
	( 'Comic', 'Electric Town Bookstore', 'sensei-san best', 2011, false, 'Seinen', 5 ),
	( 'Comic', 'Girl Meets Bear', 'I''m not really sure myself', 2013, false, 'Seinen', 5 ),
	( 'Comic', 'Sunshine Sketch', '( X''___________''X)', 2004, false, 'Seinen', 4 ),
	( 'Comic', 'Let''s have a meal together!', 'food', 2012, false, 'Seinen', 5 );

INSERT INTO authors
	( given_name, surname, native_name, sex )
	VALUES
	( 'Toru', 'Oikawa', '及川 徹', 'Female' ),
	( 'Yusuke', 'Kishi', '貴志 祐介', 'Male' ),
	( 'Hajime', 'Isayama', '諫山 創', 'Male' ),
	( 'Chihiro', 'Ishizuka', '石塚 千尋', NULL ),
	( 'Yu', 'Sasuga', '貴家 悠', 'Male' ),
	( 'Kenichi', 'Tachibana', '橘 賢一', 'Male' ),
	( 'Koji', 'Mori', '森 恒二', 'Male' ),
	( 'Asato', 'Mizu', '水 あさと', 'Male' ),
	( 'Masume', 'Yoshimoto', '吉元 ますめ', NULL ),
	( 'Ume', 'Aoki', '蒼樹 うめ', 'Female' ),
	( 'Sei', 'Takano', '高野 聖', 'Male' );

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
	( 9, 11, 3 );

INSERT INTO translation_groups
	( name )
	VALUES
	( 'display: none;' ),
	( 'Mixini Studios' ),
	( 'NEO ZEED Marine Stronghold' ),
	( 'Duwang' );

INSERT INTO translation_projects
	( series_id )
	VALUES
	(1), (2), (3), (4), (5), (6), (9);

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
	( 9, 1 );

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
