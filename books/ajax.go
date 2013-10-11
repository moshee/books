package books

import (
	"database/sql"
	"github.com/moshee/gas"
	"strconv"
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

	if (existingVote < 0 && vote < 0) || (existingVote > 0 && vote > 0) {
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
				t.spoiler,
				t.weight
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
	} else {
		// user made a vote but opposite. do the update.
		err = gas.QueryRow(tag, `
			WITH bt AS (
				SELECT
					t.id,
					t.series_id,
					btn.name,
					t.spoiler,
					t.weight
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

	// duplicating the logic that's supposedly already done on the database...
	// don't wanna do another query...
	tag.Weight += vote

	g.Render("books", "tag-link", tag)
}
