package books

import (
	//"database/sql"
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
)

func Index(g *gas.Gas) {
	releases := make([]*Release, 20)
	rows, err := gas.DB.Query("SELECT * FROM books.recent_releases LIMIT 20")
	if err != nil {
		g.Render("books", "index-error", err)
		return
	}

	for i := 0; rows.Next(); i++ {
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
		releases[i] = r
	}

	g.Render("books", "index", &struct {
		Releases []*Release
		Series   []*BookSeries
		News     []*NewsPost
	}{
		releases,
		nil,
		nil,
	})
}
