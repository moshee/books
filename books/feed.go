package books

import (
	"bytes"
	"github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"html/template"
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
	ReleaseOutput: FeedOutput{
		Head: `
			SELECT releases.*
			FROM
				books.recent_releases releases,
				books.feeds,`,

		Body: []string{
			SeriesInput: `
				books.book_series series
			WHERE series.id = releases.series_id
			  AND series.id = ANY ( feeds.include )
			  AND series.id != ALL ( feeds.exclude )
			`,

			AuthorInput: `
				books.authors,
				books.production_credits credits,
				books.book_series series
			WHERE series.id = releases.series_id 
			  AND series.id = credits.series_id
			  AND author.id = credits.author_id
			  AND author.id = ANY ( feeds.include )
			  AND author.id != ALL ( feeds.exclude )`,

			DemographicInput: `
				
			`,

			TagInput: `
				
			`,

			MagazineInput: `
				
			`,

			PublisherInput: `
				
			`,

			GroupInput: `
				
			`,
		},

		Tail: `
			  AND feeds.id = $1
			ORDER BY releases.release_date DESC`,

		Items: func() interface{} {
			var items []Release
			return &items
		},
	},
	SeriesOutput: FeedOutput{
		Head: `
			SELECT DISTINCT ON (series.id)
				series.id,
				series.name,
			FROM
				books.book_series series,
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
				books.book_tag_names tag_names
			WHERE series.id    = tags.series_id
			  AND tag_names.id = tags.tag_id
			  AND tag_names.id = ANY ( feeds.include )
			  AND tag_names.id != ALL ( feeds.exclude )
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
	InputKind   FeedInputKind
	OutputKind  FeedOutputKind
	Ref         string
	Include     pg.IntArray
	Exclude     pg.IntArray
	Creator     *User
	Title       string
	Description string
	DateCreated time.Time

	Items interface{}
}

// Execute the feed's associated template and return the output as safe HTML
func (self *Feed) Render() template.HTML {
	t := gas.Templates["books"].Lookup("feed-" + self.OutputKind.String())
	if t == nil {
		return template.HTML("Error rendering feed '" + self.Title +
			"': no template found for '" + self.OutputKind.String() + "'")
	}

	buf := new(bytes.Buffer)
	err := t.Execute(buf, self.Items)
	if err != nil {
		return template.HTML("Error rendering for feed '" + self.Title + "': " + err.Error())
	}

	return template.HTML(buf.Bytes())
}

// Generate and execute the query, populating Items so that it can be used in
// Render.
func (self *Feed) Populate() error {
	output := FeedOutputs[self.OutputKind]
	query := output.MakeQuery(self.InputKind)
	self.Items = output.Items()

	return gas.Query(self.Items, query, self.Id)
}
