package books

import (
	"database/sql"
	"errors"
	"github.com/moshee/gas"
	"strconv"
	"unicode"
)

type AJAXResponse struct {
	Ok      bool   `json:"ok"`
	Message string `json:"msg"`
}

func Login(g *gas.Gas) {
	if err := g.SignIn(); err != nil {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, err.Error()})
		// TODO: gas.Log(gas.Warning, "books: Login: %v", err)
		// TODO: g.JSON(&AJAXResponse{false, "There was an error creating your session. This error has been logged. Please try again later or complain about it."}
		return
	}

	user := g.User().(*User)

	g.Render("books", "user-cp", user)
	if page := g.FormValue("page"); len(page) > 0 {
		g.Render("books", "cp-"+page, user)
	}
}

func Logout(g *gas.Gas) {
	if err := g.SignOut(); err != nil {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	g.Render("books", "user-cp", nil)
}

var (
	errUsernameEmpty        = errors.New("I'm sorry, did you type in a username? I don't see it.")
	errUsernameInvalidChars = errors.New("Let's stick to normal letters, shall we? I'll take _ - ' ` as well.")
	errUsernameTooLong      = errors.New("How do you expect me to remember a name that long? Let's keep it to 30 characters or less.")
	errUsernameNoLetters    = errors.New("Is a single letter in there too much to ask?")
	errUsernameTaken        = "I already know someone called <NAME>. Got another name I can use so I don't get confused?"
	validRanges             = []*unicode.RangeTable{
		unicode.Letter,
		unicode.Digit,
	}
	validChars = []rune{'_', '-', '\'', '`'}
)

func validateUsername(name string) error {
	length := len(name)
	switch {
	case length == 0:
		return errUsernameEmpty
	case length > 30:
		return errUsernameTooLong
	}

	anyLetters := false

	for _, ch := range name {
		ok := false
		for _, valid := range validChars {
			if ch == valid {
				ok = true
				break
			}
		}
		if !ok {
			if !unicode.IsOneOf(validRanges, ch) {
				return errUsernameInvalidChars
			}
			anyLetters = true
		}
	}

	if !anyLetters {
		return errUsernameNoLetters
	}

	return nil
}

func ValidateUsername(g *gas.Gas) {
	name := g.FormValue("username")
	if err := validateUsername(name); err != nil {
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	id := -1
	gas.DB.QueryRow("SELECT id FROM books.users WHERE name = $1", name).Scan(&id)
	if id > 0 {
		g.JSON(&AJAXResponse{false, errUsernameTaken})
		return
	}
	if len(name) <= 3 {
		g.JSON(&AJAXResponse{true, "You sure lucked out with that name, <NAME>."})
	} else {
		g.JSON(&AJAXResponse{true, "<NAME>, is it? Nice to meet you."})
	}
}

func Signup(g *gas.Gas) {
	if user := g.User().(*User); user != nil {
		g.Reroute("/", 302, newBanner("friendly", "You already have an account!", "We're flattered that you like the site so much that you need <strong>another</strong> account, but just one will be enough."))
		return
	}
	g.Render("books", "signup", nil)
}

func PostSignup(g *gas.Gas) {

}

func TagInfo(g *gas.Gas) {
	name := g.FormValue("tag")
	if name == "" {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, "tag name not given"})
		return
	}

	var (
		user = g.User().(*User)
		tag  = new(struct {
			Id          int
			Name        string
			Description sql.NullString
			Opinion     int
		})
		err error
	)

	if user == nil {
		err = gas.QueryRow(tag, "SELECT * FROM books.book_tag_names WHERE name = $1", name)
	} else {
		seriesId := 0
		seriesId, err = strconv.Atoi(g.FormValue("series"))
		if err != nil {
			g.WriteHeader(400)
			g.JSON(&AJAXResponse{false, err.Error()})
			return
		}

		err = gas.QueryRow(tag, `
			SELECT
				btn.*,
				COALESCE(btc.vote, 0) opinion
			FROM
				books.book_tag_names btn,
				books.book_tags bt
				LEFT JOIN books.book_tag_consensus btc ON 
					btc.book_tag_id = bt.id
					AND btc.user_id = $1
			WHERE
				bt.tag_id = btn.id
				AND btn.name = $2
				AND bt.series_id = $3
		`, user.Id, name, seriesId)
	}
	if err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	g.Render("books", "tag-info", tag)
}

func TagVote(g *gas.Gas) {
	name, action := g.FormValue("tag"), g.FormValue("action")
	if name == "" || action == "" {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, "tag name or action not given"})
		return
	}

	seriesId, err := strconv.Atoi(g.FormValue("series"))
	if err != nil {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	user := g.User().(*User)
	if user == nil {
		g.WriteHeader(403)
		g.JSON(&AJAXResponse{false, "not logged in"})
		return
	}

	vote := 0
	switch action {
	case "up":
		vote = user.VoteWeight
	case "down":
		vote = -user.VoteWeight
	case "remove":
		_, err := gas.DB.Exec(`
			DELETE FROM
				books.book_tag_consensus btc
			USING
				books.book_tags bt
				books.book_tag_names btn
			WHERE btc.user_id  = $1
			  AND bt.id        = btc.book_tag_id
			  AND bt.tag_id    = btn.id
			  AND btn.name     = $2
			  AND bt.series_id = $3
			  `, user.Id, name, seriesId)
		if err != nil {
			g.WriteHeader(500)
			g.JSON(&AJAXResponse{false, "error removing vote: " + err.Error()})
		} else {
			g.JSON(&AJAXResponse{true, ""})
		}
		return
	default:
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, "invalid vote action: " + action})
		return
	}

	// see if user already submitted the vote they're trying now
	// yes:
	//   error
	// no:
	//   if vote was made but opposite:
	//     update consensus returning tag
	//   else:
	//     insert into consensus returning tag

	existingVote := 0

	err = gas.DB.QueryRow(`
		SELECT
			COALESCE(btc.vote, 0)
		FROM
			books.book_tag_names btn,
			books.book_tags bt
			LEFT JOIN books.book_tag_consensus btc ON
				btc.book_tag_id = bt.id
				AND btc.user_id = $1
		WHERE
			bt.tag_id = btn.id
			AND btn.name = $2
			AND bt.series_id = $3
		`, user.Id, name, seriesId).Scan(&existingVote)

	if err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	if existingVote != 0 && (existingVote >= 0) != (vote <= 0) {
		// oh no! user already did this vote. error.
		// The javascript SHOULD in theory prevent this from happening, but
		// it's better to be safe.
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, "you already voted this tag " + action})
		return
	}

	tag := new(BookTag)
	if existingVote == 0 {
		// we're safe; do the insert
		err = gas.QueryRow(tag, `
			SELECT
				t.id,
				t.series_id,
				btn.name,
				t.spoiler
			FROM
				books.book_tags t,
				books.book_tag_names btn
			WHERE t.tag_id = btn.id
			  AND btn.name = $1
			  AND t.series_id = $2
			`, name, seriesId)

		if err != nil {
			g.WriteHeader(500)
			g.JSON(&AJAXResponse{false, err.Error()})
			return
		}

		_, err = gas.DB.Exec(`
			INSERT INTO books.book_tag_consensus
				( user_id, book_tag_id, vote )
			VALUES
				( $1, $2, $3 )
			`, user.Id, tag.Id, vote)

		if err != nil {
			g.WriteHeader(500)
			g.JSON(&AJAXResponse{false, err.Error()})
			return
		}
	} else {
		// user made a vote but opposite. do the update.
		err = gas.QueryRow(tag, `
			WITH bt AS (
				SELECT
					t.id,
					t.series_id,
					btn.name,
					t.spoiler
				FROM
					books.book_tags t,
					books.book_tag_names btn
				WHERE t.tag_id = btn.id
				  AND btn.name = $1
				  AND t.series_id = $2
			)
			UPDATE books.book_tag_consensus btc
			SET
				vote      = $3,
				vote_date = now()
			FROM bt
			WHERE btc.book_tag_id = (SELECT id FROM bt)
			  AND btc.user_id = $4
			RETURNING bt.*
			`, name, seriesId, vote, user.Id)
	}
	if err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	err = gas.DB.QueryRow(`
		SELECT weight
		FROM   books.book_tags
		WHERE  id = $1
		`, tag.Id).Scan(&tag.Weight)

	if err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	g.Render("books", "tag-link", tag)
}
