package books

import (
	"database/sql"
	"github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"strconv"
	"time"
)

type BookTag struct {
	Id       int    `json:"id"`
	SeriesId int    `json:"series_id"`
	Name     string `json:"name"`
	Spoiler  bool   `json:"spoiler"`
	Weight   int    `json:"weight"`
}

func (self BookTag) Opacity() float32 {
	w := float32(self.Weight)
	if w > 0.0 {
		// pretty close to 1.0 pretty fast (starts at y ~ 0.75 for
		// x = 0)
		return 1.0 - (2.0 / (w + 8.0))
	} else {
		// Almost linear down to around 0.3 for x = -5 (ends at
		// y ~ 0.6 for x = 0)
		return 1.0 - (5.0 / (w + 12.0))
	}
}

func (self BookTag) Color() int {
	if self.Weight < 0.0 {
		return 0x444444
	}

	f := 1.0 - (3.0 / (float32(self.Weight) + 3.0))

	// range: 0x00 (high) .. 0x44 (low)
	rg := int(float32(0x44) * (1 - f))

	// range: 0xff (high) .. 0x44 (low)
	b := int(float32(0xff-0x44)*f) + 0x44

	return rg<<16 | rg<<8 | b
}

type BookTags []BookTag

func (self BookTags) HasSpoiler() bool {
	for _, s := range self {
		if s.Spoiler {
			return true
		}
	}
	return false
}

type BookTagConsensus struct {
	Id int
	User
	*BookTag
	Vote     int
	VoteDate time.Time
}

type CharacterTag struct {
	Id int
	*Character
	Name    string
	Spoiler bool
	Weight  int
}

type CharacterTagConsensus struct {
	Id int
	*User
	*CharacterTag
	Vote     int
	VoteDate time.Time
}

type Tags struct {
	Ids      pg.IntArray    `sql:"tag_ids"`
	Names    pg.StringArray `sql:"tag_names"`
	Weights  pg.IntArray    `sql:"tag_weights"`
	Spoilers pg.BoolArray   `sql:"tag_spoilers"`
}

func (self *Tags) WeightClass(i int) int {
	w := float64(self.Weights[i])
	if w < 0.0 {
		return 0
	}

	// this should give a graph with a horizontal asymptote at y = 255, with
	// y being very close to this at around x = 20. The y-intercept is very
	// close to zero.
	return int(255 * (1.0 - (3.0 / (w + 3.0))))
}

// Controllers

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
