package books

import (
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	"strconv"
)

func Index(g *gas.Gas) {
	releases := make([]Release, 0, 15)
	g.Populate(&releases, "SELECT * FROM books.recent_releases LIMIT 15")

	releaseFeed := &Feed{
		Kind:  "release",
		Title: "Latest Releases",
		Items: releases,
	}

	series := make([]BookSeries, 0, 15)
	g.Populate(&series, "SELECT * FROM books.latest_series LIMIT 15")

	seriesFeed := &Feed{
		Kind:  "series",
		Title: "New Titles",
		Items: series,
	}

	news := make([]NewsPost, 0, 3)
	g.Populate(&news, "SELECT * FROM books.latest_news LIMIT 3")

	newsFeed := &Feed{
		Kind:  "news",
		Title: "Site News",
		Items: news,
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
		[]*Feed{releaseFeed, seriesFeed, newsFeed},
		g.User().(*User),
		banner,
	})
}

func SeriesIndex(g *gas.Gas) {

}

func SeriesPage(g *gas.Gas) {
	id, err := strconv.Atoi(g.Args["id"])
	if err != nil {
		g.Error(404, err)
	}

	series := new(BookSeries)
	g.Populate(series, "SELECT * FROM books.series_page WHERE id = $1", id)

	g.Render("books", "series", &struct {
		Series *BookSeries
		User   *User
	}{
		series,
		g.User().(*User),
	})
}

func AuthorsIndex(g *gas.Gas) {

}

func AuthorPage(g *gas.Gas) {

}
