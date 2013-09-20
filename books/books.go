package books

import (
	//"database/sql"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
)

func Index(g *gas.Gas) {
	releases := make([]*Release, 20)
	rows, err := gas.DB.Query("SELECT * FROM recent_releases LIMIT 20")
	if err != nil {
		g.Render("books", "index-error", err)
		return
	}

	for i := 0; rows.Next(); i++ {
		r := new(Release)
		s := new(BookSeries)
		g := new(TranslationGroup)

		err = rows.Scan(&r.Id, &s.Id, &s.Title, &g.Id, &g.Name, &r.Language, &r.ReleaseDate, &r.Notes, &r.IsLastRelease, &r.Volume, &r.Extra)
		if err != nil {
			g.Render("books", "index-error", err)
			return
		}

		r.BookSeries = s
		r.TranslationGroup = g
		releases[i] = r
	}
	g.Render("books", "index", nil)
}
