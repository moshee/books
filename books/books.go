package books

import (
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
)

func Index(g *gas.Gas) {
	releases := make([]Release, 0, 15)
	g.Populate(&releases, "SELECT * FROM books.recent_releases LIMIT 15")

	releaseFeed := &Feed{
		OutputKind: ReleaseOutput,
		Title:      "Latest Releases",
		Items:      releases,
	}

	series := make([]BookSeries, 0, 15)
	g.Populate(&series, "SELECT * FROM books.latest_series LIMIT 15")

	seriesFeed := &Feed{
		OutputKind: SeriesOutput,
		Title:      "New Titles",
		Items:      series,
	}

	var banner *Banner

	if rr := g.RerouteInfo; rr != nil {
		banner = new(Banner)
		if err := rr.Recover(banner); err != nil {
			banner = nil
			gas.Log(gas.Warning, "books index reroute: %v", err)
		}
	}

	g.Render("books", "index", &struct {
		Feeds  []*Feed
		User   *User
		Banner *Banner
	}{
		[]*Feed{releaseFeed, seriesFeed},
		g.User().(*User),
		banner,
	})
}
