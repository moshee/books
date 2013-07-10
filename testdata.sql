INSERT INTO publishers
	( name, summary )
	VALUES
	( 'Kodansha', NULL ),
	( 'Shueisha', NULL ),
	( 'Hakusensha', 'they do some pretty good stuff' ),
	( 'Media Factory', 'denki-gai is good, comic flapper is good' );

INSERT INTO magazines
	( title, publisher, summary )
	VALUES
	( 'Bessatsu Shounen Magazine', 1, 'eotens' ),
	( 'Weekly Young Jump', 2, 'johj' ),
	( 'Young Animal', 3, 'KAAAAAAIIIIIIIII' ),
	( 'Comic Flapper', 4, 'chocolate panic' );

INSERT INTO book_series
	( kind, title, summary, vintage, nsfw, demographic, magazine_id )
	VALUES
	( 'Comic', 'From the New World', 'so many scifi tropes', 2012, true, 'Shounen', 1 ),
	( 'Comic', 'The Eotena Onslaught', 'eotens', 2009, false, 'Shounen', 1 ),
	( 'Comic', 'Flying Witch', 'it''s like yotsuba with magic', 2012, false, 'Shounen', 1 ),
	( 'Comic', 'Terra ForMars', 'johj', 2011, true, 'Seinen', 2 ),
	( 'Comic', 'Suicide Island', 'goats', 2008, true, 'Seinen', 3 ),
	( 'Comic', 'Electric Town Bookstore', 'sensei-san best', 2011, false, 'Seinen', 4 ),
	( 'Comic', 'Girl Meets Bear', 'I''m not really sure myself', 2013, false, 'Seinen', 4 ),
	( 'Comic', 'Let''s have a meal together!', 'food', 2012, false, 'Seinen', 4 );

INSERT INTO authors
	( given_name, surname, sex )
	VALUES
	( 'Toru', 'Oikawa', 'Female' ),
	( 'Yusuke', 'Kishi', 'Male' ),
	( 'Hajime', 'Isayama', 'Male' ),
	( 'Chihiro', 'Ishizuka', NULL ),
	( 'Yu', 'Sasuga', 'Male' ),
	( 'Kenichi', 'Tachibana', 'Male' ),
	( 'Koji', 'Mori', 'Male' ),
	( 'Asato', 'Mizu', 'Other' ),
	( '???', '?????', NULL ),
	( 'Sei', 'Takano', 'Male' );

