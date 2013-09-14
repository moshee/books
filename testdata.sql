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
