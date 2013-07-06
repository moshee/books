package books

import (
	"database/sql"
	// "github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"strconv"
	"time"
)

type PictureLinker interface {
	PictureLink() string
}

type (
	SeriesKind  int
	Demographic int
	Sex         int
	Credit      int
	Relation    int
	Language    int
	Privileges  int
	ReadStatus  int
)

const (
	Comic SeriesKind = iota
	Novel
)

const (
	Shounen Demographic = iota
	Shoujo
	Seinen
	Josei
)

const (
	Male Sex = iota
	Female
	Other
)

const (
	Scenario Credit = iota
	Art
	Illustration
	Music
)

const (
	Related Relation = iota
	Sequel
	Prequel
	Adaptation
)

const (
	Banned Privileges = 1 << iota
	Administrator
	Moderator
	Contributor
)

func (self Privileges) Is(other Privileges) bool {
	return self&other != 0
}

func (self Privileges) Isnt(other Privileges) bool {
	return self&other == 0
}

const (
	Read ReadStatus = iota
	Owned
	Skipped
)

type BookSeries struct {
	Id int
	SeriesKind
	Title       string
	OtherTitles pg.StringArray
	Summary     sql.NullString
	Vintage     int
	DateAdded   time.Time
	LastUpdated time.Time
	Finished    bool
	NSFW        bool
	AvgRating   sql.NullFloat64
	RatingCount int
	Demographic
	*Magazine

	Related []RelatedSeries
}

type Author struct {
	Id         int
	Name       string
	NativeName string
	Aliases    pg.StringArray
	Picture    bool
	Birthday   time.Time
	Bio        string
	Sex
}

type ProductionCredit struct {
	*BookSeries
	*Author
	Credit
}

type RelatedSeries struct {
	*BookSeries
	Relation Relation
}

type TranslationGroup struct {
	Id               int
	Name             string
	Summary          sql.NullString
	AvgRating        sql.NullFloat64
	AvgProjectRating sql.NullFloat64
	AvgReleaseRate   time.Duration
}

type Chapter struct {
	Id          int
	Volume      sql.NullInt64
	DisplayName string
	SortNum     int
	Title       sql.NullString
}

type Release struct {
	Id int
	*BookSeries
	*TranslationGroup
	*TranslationProject
	Lang          Language
	ReleaseDate   time.Time
	Notes         sql.NullString
	IsLastRelease bool
	Chapters      []*Chapter
}

type TranslationProject struct {
	Id int
	*BookSeries
	*TranslationGroup
	StartDate time.Time
	EndDate   time.Time
}

func (self *TranslationProject) Members() []*User {
	return nil
}

type User struct {
	Id   int
	Name string
	Pass []byte
	Salt []byte
	Privileges
	VoteWeight   int
	Summary      sql.NullString
	RegisterDate time.Time
	LastActive   time.Time
	Avatar       bool
}

func (self *User) PictureLink() string {
	if self.Avatar {
		return "u" + strconv.Itoa(self.Id) + ".jpg"
	} else {
		return ""
	}
}

type OwnedChapter struct {
	*Chapter
	Status   ReadStatus
	DateRead time.Time
}

type Magazine struct {
	Id    int
	Title string
	*Publisher
	DateAdded time.Time
	Summary   sql.NullString
}

type Publisher struct {
	Id        int
	Name      string
	DateAdded time.Time
	Summary   sql.NullString
}

type LinkKind struct {
	Id   int
	Name string
}

type Link struct {
	LinkKind
	URL string
}

type Tag struct {
	Id   int
	Name string
}

type BookTag struct {
	Id int
	BookSeries
	Tag
	Spoiler bool
	Weight  float32
}

type TagConsensus struct {
	User
	BookTag
	Vote     int
	VoteDate time.Time
}

type Rating struct {
	Id int
	User
	*Review
	Rating   int
	RateDate time.Time
}

type Review struct {
	Id int
	*Rating
	Body string
}
