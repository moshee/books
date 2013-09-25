package books

import (
	//"database/sql"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	"sort"
	"time"
)

func Index(g *gas.Gas) {
	releases := make([]Release, 20)
	if err := gas.Query(&releases, "SELECT * FROM books.recent_releases LIMIT 20"); err != nil {
		g.Error(500, err)
		return
	}
	for _, r := range releases {
		sort.Sort(r.TranslationGroups)
	}

	series := make([]BookSeries, 10)
	if err := gas.Query(&series, "SELECT * FROM books.latest_series LIMIT 10"); err != nil {
		g.Error(500, err)
		return
	}

	news := new(NewsPost)
	if err := gas.QueryRow(news, "SELECT * FROM books.latest_news LIMIT 1"); err != nil {
		g.Error(500, err)
		return
	}

	var user *User

	if sess, err := g.Session(); sess != nil {
		user = new(User)
		err = gas.QueryRow(user, "SELECT * FROM books.users WHERE name = $1", sess.Who)
		if err != nil {
			g.Error(500, err)
		}
	}

	g.Render("books", "index", &struct {
		Releases []Release
		Series   []BookSeries
		News     *NewsPost
		Now      time.Time
		User     *User
	}{
		releases,
		series,
		news,
		time.Now(),
		user,
	})
}
