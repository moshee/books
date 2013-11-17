package books

import (
	"database/sql"
	"github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"time"
)

type BookSeries struct {
	Id          int    `sql:"series_id"`
	Title       string `sql:"series_title"`
	NativeTitle string
	OtherTitles pg.StringArray
	SeriesKind  `sql:"kind"`
	Summary     sql.NullString `sql:"series_summary"`
	Vintage     int
	DateAdded   time.Time
	LastUpdated time.Time
	Finished    bool
	NSFW        bool
	AvgRating   sql.NullFloat64 `sql:"series_avg_rating"`
	RatingCount int             `sql:"series_rating_count"`
	Demographic
	*Magazine
	HasCover bool

	TagArr *Tags
}

func (self *BookSeries) Related() (r []RelatedSeries) {
	err := gas.Query(&r, "SELECT * FROM books.related_series_view WHERE series_id = $1", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Related: %v", err)
		return nil
	}
	return
}

func (self *BookSeries) Characters() (cs Characters) {
	err := gas.Query(&cs, "SELECT * FROM books.series_characters WHERE series_id = $1", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Characters: %v", err)
		return nil
	}
	return
}

func (self *BookSeries) Reviews() (ratings []BookRating) {
	err := gas.Query(&ratings, `
		SELECT *
		FROM   books.series_book_ratings
		WHERE  series_id = $1
		LIMIT  5`, self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Reviews: %v", err)
		return nil
	}
	return
}

func (self *BookSeries) Releases() (releases []Release) {
	err := gas.Query(&releases, "SELECT * FROM books.recent_releases WHERE series_id = $1 LIMIT 10", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Releases: %v", err)
	}
	return
}

func (self *BookSeries) Credits() (credits []ProductionCredit) {
	err := gas.Query(&credits, "SELECT * FROM books.series_credits WHERE series_id = $1", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Credits: %v", err)
	}
	return
}

func (self *BookSeries) Tags() (tags BookTags) {
	err := gas.Query(&tags, "SELECT * FROM books.series_tags WHERE series_id = $1", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Tags: %v", err)
	}

	return
}

type License struct {
	Id           int    `sql:"licensor_id"`
	Name         string `sql:"licensor_name"`
	Country      string `sql:"licensed_in"`
	DateLicensed time.Time
}

type RelatedSeries struct {
	SeriesId int
	Id       int    `sql:"related_id"`
	Title    string `sql:"related_title"`
	Relation SeriesRelation
}

/*
func (self *BookSeries) LimitedTags(n int) *Tags {
	if self.Tags == nil || n > len(self.Tags.Ids) {
		return self.Tags
	} else {
		return &Tags{
			self.Tags.Ids[:n],
			self.Tags.Names[:n],
			self.Tags.Weights[:n],
			self.Tags.Spoilers[:n],
		}
	}
}
*/

func (self *BookSeries) RatingStars() []string {
	if !self.AvgRating.Valid {
		return nil
	}

	s := make([]string, 5)
	round_max := int(self.AvgRating.Float64 + 0.5)

	for i := range s {
		if i < round_max {
			s[i] = "on"
		} else {
			s[i] = "off"
		}
	}
	return s
}

type SeriesLicense struct {
	Id int
	*BookSeries
	*Publisher
	Country      string
	DateLicensed time.Time
}

type Publisher struct {
	Id        int    `sql:"publisher_id"`
	Name      string `sql:"publisher_name"`
	DateAdded time.Time
	Summary   sql.NullString
}

type Magazine struct {
	Id    int    `sql:"magazine_id"`
	Title string `sql:"magazine_title"`
	*Publisher
	DateAdded time.Time
	Summary   sql.NullString
}

type (
	SeriesKind     int
	Demographic    int
	SeriesRelation int
)

func (self SeriesKind) String() string {
	return []string{
		"Comic",
		"Novel",
		"Webcomic",
	}[self]
}

func (d Demographic) String() string {
	return []string{
		"Shōnen",
		"Shōjo",
		"Seinen",
		"Josei",
		"Kodomo",
		"Seijin",
	}[d]
}

func (d Demographic) URLString() string {
	return []string{
		"shonen",
		"shojo",
		"seinen",
		"josei",
		"kodomo",
		"seijin",
	}[d]
}

func (self SeriesRelation) String() string {
	return []string{
		"Original work",
		"Alternate version",
		"Sequel",
		"Prequel",
		"Spin-off",
		"Adaptation",
		"Shares character",
	}[self]
}

// Controllers

func SeriesIndex(g *gas.Gas) {

}

func SeriesPage(g *gas.Gas) {
	id, err := g.IntArg("id")
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
