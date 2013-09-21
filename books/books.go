package books

import (
	//"database/sql"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	"time"
)

func Index(g *gas.Gas) {
	releases := make([]*Release, 0, 20)
	rows, err := gas.DB.Query("SELECT * FROM books.recent_releases LIMIT 20")
	if err != nil {
		g.Render("books", "index-error", err)
		return
	}

	for rows.Next() {
		r := new(Release)
		s := new(BookSeries)
		t := new(TranslationGroup)

		err = rows.Scan(&r.Id, &r.Language, &r.ReleaseDate, &r.IsLastRelease, &r.Volume, &r.Extra, &r.Chapters, &s.Id, &s.Title, &t.Id, &t.Name)
		if err != nil {
			g.Render("books", "index-error", err)
			return
		}

		r.BookSeries = s
		r.TranslationGroup = t
		releases = append(releases, r)
	}

	series := make([]*BookSeries, 0, 10)
	rows, err = gas.DB.Query("SELECT * FROM books.latest_series LIMIT 10")
	if err != nil {
		g.Render("books", "index-error", err)
		return
	}

	for rows.Next() {
		s := new(BookSeries)
		err := rows.Scan(&s.Id, &s.Title, &s.SeriesKind, &s.Vintage, &s.DateAdded, &s.NSFW, &s.AvgRating, &s.Tags)
		if err != nil {
			g.Render("books", "index-error", err)
			return
		}

		series = append(series, s)
	}

	n := new(NewsPost)
	u := new(User)

	row := gas.DB.QueryRow("SELECT * FROM books.latest_news LIMIT 1")

	if err := row.Scan(&n.Id, &u.Id, &u.Name, &n.Category, &n.DatePosted, &n.Title, &n.Body); err != nil {
		g.Render("books", "index-error", err)
		return
	}

	n.User = u

	g.Render("books", "index", &struct {
		Releases []*Release
		Series   []*BookSeries
		News     *NewsPost
		Now      time.Time
	}{
		releases,
		series,
		n,
		time.Now(),
	})
}
