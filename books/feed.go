package books

import (
	"bytes"
	"encoding/json"
	"github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"html/template"
	"io"
	"time"
)

type FeedInputKind int

const (
	SeriesInput FeedInputKind = iota
	AuthorInput
	DemographicInput
	TagInput
	MagazineInput
	PublisherInput
	GroupInput
)

func (i FeedInputKind) String() string {
	return []string{
		"series",
		"authors",
		"demographics",
		"tags",
		"magazines",
		"publishers",
		"groups",
	}[i]
}

type FeedOutputKind int

const (
	ReleaseOutput FeedOutputKind = iota
	SeriesOutput
)

func (o FeedOutputKind) String() string {
	return []string{
		"release",
		"series",
	}[o]
}

// The query.
type FeedOutput struct {
	Head  string
	Body  []string
	Tail  string
	Items func() interface{}
}

func (self FeedOutput) MakeQuery(in FeedInputKind) string {
	return self.Head + self.Body[in] + self.Tail
}

var FeedOutputs = []FeedOutput{
	ReleaseOutput: {
		Head: `
			WITH release AS (
				SELECT * FROM books.recent_releases
			)
			SELECT release.*
			FROM
				release,
				books.feeds feed`,

		Body: []string{
			SeriesInput: `,
				books.book_series series
			WHERE series.id = releases.series_id
			  AND series.id = ANY ( feed.include )
			  AND series.id != ALL ( feed.exclude )
			`,

			AuthorInput: `,
				books.authors author,
				books.production_credits credit,
				books.book_series series
			WHERE series.id = release.series_id 
			  AND series.id = credit.series_id
			  AND author.id = credit.author_id
			  AND author.id = ANY ( feed.include )
			  AND author.id != ALL ( feed.exclude )`,

			DemographicInput: `,
				
			`,

			TagInput: `,
				books.book_tags      tag,
				books.book_tag_names tag_name,
				books.book_series    series
			WHERE series.id    = tag.series_id
			  AND series.id    = release.series_id
			  AND tag_name.id  = tag.tag_id
			  AND release.tag && feed.include
			  AND NOT release.tag && feed.exclude
			`,

			MagazineInput: `,
				
			`,

			PublisherInput: `,
				
			`,

			GroupInput: `,
				
			`,
		},

		Tail: `
			  AND feed.id = $1
			ORDER BY release.release_date DESC
			`,

		Items: func() interface{} {
			var items []Release
			return &items
		},
	},
	SeriesOutput: {
		Head: `
			WITH series AS (
				SELECT
					id,
					title
				FROM
					books.book_series
				ORDER BY date_added DESC
			)
			SELECT
				series.*
			FROM
				books.feeds`,

		Body: []string{
			SeriesInput: `
			WHERE series.id = ANY ( feeds.include )
			  AND series.id != ALL ( feeds.exclude )
			`,

			AuthorInput: `,
				books.authors,
				books.production_credits credits
			WHERE author.id = credits.author_id
			  AND series.id = credits.series_id
			  AND author.id = ANY ( feeds.include )
			  AND author.id != ALL ( feeds.exclude )
			`,

			DemographicInput: `
			WHERE series.demographic = ANY ( feeds.include )
			  AND series.demographic != ALL ( feeds.exclude )
			`,

			TagInput: `,
				books.book_tags      tags,
				books.book_tag_names tag_names,
			WHERE series.id    = tags.series_id
			  AND tag_names.id = tags.tag_id
			  AND series.tags && feeds.include
			  AND NOT series.tags && feeds.exclude
			`,

			MagazineInput: `,
				books.magazines
			WHERE magazine.id = series.magazine_id
			  AND magazine.id = ANY ( feeds.include )
			  AND magazine.id != ALL ( feeds.exclude )
			`,

			PublisherInput: `,
				books.magazines,
				books.publishers
			WHERE magazine.id  = series.magazine_id
			  AND publisher.id = magazine.publisher_id
			  AND publisher.id = ANY ( feeds.include )
			  AND publisher.id != ALL ( feeds.exclude )
			`,

			GroupInput: `,
				
			`,
		},

		Tail: `
			  AND feeds.id = $1
			ORDER BY series.date_added DESC`,

		Items: func() interface{} {
			var items []BookSeries
			return &items
		},
	},
}

type Feed struct {
	Id          int
	InputKind   FeedInputKind  `json:"input"`
	OutputKind  FeedOutputKind `json:"output"`
	Ref         string         `json:"ref,omitempty"`
	Include     pg.IntArray    `json:"include"`
	Exclude     pg.IntArray    `json:"exclude"`
	Creator     *User
	Title       string    `json:"name"`
	Description string    `json:"description"`
	DateCreated time.Time `json:"dateCreated"`

	Items interface{} `json:"items"`
}

// Execute the feed's associated template and return the output as safe HTML
func (self *Feed) Render() template.HTML {
	t := gas.Templates["books"].Lookup("feed-" + self.OutputKind.String())
	if t == nil {
		return template.HTML("Error rendering feed '" + self.Title +
			"': no template found for '" + self.OutputKind.String() + "'")
	}

	if self.Items == nil {
		err := self.Populate(20)
		if err != nil {
			return template.HTML("Error rendering feed '" + self.Title +
				"': " + err.Error())
		}
	}

	buf := new(bytes.Buffer)
	err := t.Execute(buf, self.Items)
	if err != nil {
		return template.HTML("Error rendering feed '" + self.Title +
			"': " + err.Error())
	}

	return template.HTML(buf.Bytes())
}

// Generate and execute the query, populating Items so that it can be used in
// Render. If limit is >= 0, a LIMIT clause will be added to the query.
func (self *Feed) Populate(limit int) error {
	output := FeedOutputs[self.OutputKind]
	query := output.MakeQuery(self.InputKind)
	self.Items = output.Items()

	if limit >= 0 {
		query += " LIMIT $2"
		return gas.Query(self.Items, query, self.Id, limit)
	}

	return gas.Query(self.Items, query, self.Id)
}

// Controllers

func PreviewFeed(g *gas.Gas) {
	buf := new(bytes.Buffer)
	defer g.Body.Close()
	io.Copy(buf, g.Body)

	feed := new(Feed)

	if err := json.Unmarshal(buf.Bytes(), feed); err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	feed.DateCreated = time.Now()
	feed.Creator = g.User().(*User)

	if err := feed.Populate(10); err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	g.Render("books", "feed-"+feed.OutputKind.String(), feed)
}
