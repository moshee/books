package books

import (
	"github.com/moshee/gas"
	//"github.com/argusdusty/Ferret"
	"strconv"
)

func Index(g *gas.Gas) {
	releases := make([]Release, 0, 15)
	if err := gas.Query(&releases, "SELECT * FROM books.recent_releases LIMIT 15"); err != nil {
		g.Error(500, err)
		return
	}

	releaseFeed := &Feed{
		"Latest Releases",
		"",
		nil,
		make([]FeedItem, len(releases)),
	}

	for i, release := range releases {
		releaseFeed.Items[i] = release
	}

	series := make([]BookSeries, 0, 15)
	if err := gas.Query(&series, "SELECT * FROM books.latest_series LIMIT 15"); err != nil {
		g.Error(500, err)
		return
	}

	seriesFeed := &Feed{
		"New Titles",
		"",
		nil,
		make([]FeedItem, len(series)),
	}

	for i, s := range series {
		seriesFeed.Items[i] = s
	}

	news := make([]NewsPost, 0, 3)
	if err := gas.Query(&news, "SELECT * FROM books.latest_news LIMIT 3"); err != nil {
		g.Error(500, err)
		return
	}

	newsFeed := &Feed{
		"Site News",
		"",
		nil,
		make([]FeedItem, len(news)),
	}

	for i, s := range news {
		newsFeed.Items[i] = s
	}

	g.Render("books", "index", &struct {
		Feeds []*Feed
		User  *User
	}{
		[]*Feed{releaseFeed, seriesFeed, newsFeed},
		g.User().(*User),
	})

	/*
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
			g.User().(*User),
		})
	*/
}

func SeriesIndex(g *gas.Gas) {

}

func SeriesPage(g *gas.Gas) {
	id, err := strconv.Atoi(g.Args["id"])
	if err != nil {
		g.Error(404, err)
	}

	series := new(BookSeries)
	if err = gas.QueryRow(series, "SELECT * FROM books.series_page WHERE id = $1", id); err != nil {
		g.Error(500, err)
		return
	}

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
