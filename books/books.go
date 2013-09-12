package books

import (
	"database/sql"
	// "github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"strconv"
	"strings"
	"time"
)

type (
	SeriesKind        int
	Demographic       int
	Sex               int
	Credit            int
	SeriesRelation    int
	Language          int
	Privileges        int
	ReadStatus        int
	BloodType         int
	CharacterRole     int
	CharacterRelation int
)

const (
	Comic SeriesKind = iota + 1
	Novel
	Webcomic
)

const (
	Shounen Demographic = iota + 1
	Shoujo
	Seinen
	Josei
)

func (d Demographic) String() string {
	switch d {
	case Shounen:
		return "Shōnen"
	case Shoujo:
		return "Shōjo"
	case Seinen:
		return "Seinen"
	case Josei:
		return "Josei"
	}
	return ""
}

const (
	Male Sex = iota + 1
	Female
	Other
)

func (s Sex) String() string {
	switch s {
	case Male:
		return "Male"
	case Female:
		return "Female"
	case Other:
		return "Other"
	}
	return ""
}

const (
	Scenario Credit = 1 << iota
	Art
	Illustration
	Music
)

func (c Credit) String() string {
	cs := make([]string, 0, 4)
	if c&Scenario != 0 {
		cs = append(cs, "Story")
	}
	if c&Art != 0 {
		cs = append(cs, "Art")
	}
	if c&Illustration != 0 {
		cs = append(cs, "Illust.")
	}
	if c&Music != 0 {
		cs = append(cs, "Music")
	}
	return strings.Join(cs, ", ")
}

const (
	Related SeriesRelation = iota + 1
	Sequel
	Prequel
	SpinOff
	Adaptation
)

const (
	Banned Privileges = 1 << iota
	Administrator
	Moderator
	Contributor
	Developer
)

func (self Privileges) Is(other Privileges) bool {
	return self&other != 0
}

func (self Privileges) Isnt(other Privileges) bool {
	return self&other == 0
}

const (
	Read ReadStatus = iota + 1
	Owned
	Skipped
)

func (s ReadStatus) String() string {
	switch s {
	case Read:
		return "Read it"
	case Owned:
		return "Have it"
	case Skipped:
		return "Skipped it"
	}
	return ""
}

const (
	Main CharacterRole = iota + 1
	Secondary
	Appears
	Cameo
)

const (
	Family CharacterRelation = iota + 1
	Friend
	Enemy
	LoveInterest
	Lover
)

const (
	O BloodType = iota + 1
	A
	B
	AB
)

func (b BloodType) String() string {
	switch b {
	case O:
		return "0"
	case A:
		return "A"
	case B:
		return "B"
	case AB:
		return "AB"
	}
	return ""
}

type BookSeries struct {
	Id int
	SeriesKind
	Title       string
	NativeTitle string
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
	Credits []ProductionCredit
	*Magazine
}

func (self *BookSeries) Related() []RelatedSeries {
	return nil
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
	Relation SeriesRelation
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

type Chapters []*Chapter

// create a representation of the list of chapters with ranges, using display
// names as necessary
func (self Chapters) String() string {
	return ""
}

type Release struct {
	Id int
	*BookSeries
	*TranslationGroup
	*TranslationProject
	Language
	ReleaseDate   time.Time
	Notes         sql.NullString
	IsLastRelease bool
	Chapters
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

func (self *User) AvatarFile() string {
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

type Character struct {
	Id          int
	Name        string
	NativeName  string
	Aliases     pg.StringArray
	Nationality string
	Birthday    string
	Age         int
	Sex
	Weight int
	Height int
	Bust   int
	Waist  int
	Hips   int
	BloodType
	Description string
	Picture     bool
}

type CharacterRole struct {
	*Character
	*BookSeries
	Role CharacterRole
}

type RelatedCharacter struct {
	*Character
	Relation CharacterRelation
}

type LinkKind struct {
	Id   int
	Name string
}

type Link struct {
	LinkKind
	URL string
}

type BookTagName struct {
	Id   int
	Name string
}

type BookTag struct {
	Id int
	BookSeries
	BookTagName
	Spoiler bool
	Weight  float32
}

type BookTagConsensus struct {
	User
	BookTag
	Vote     int
	VoteDate time.Time
}

type CharacterTagName struct {
	Id   int
	Name string
}

type CharacterTag struct {
	Id int
	Character
	CharacterTagName
	Spoiler bool
	Weight  float32
}

type CharacterTagConsensus struct {
	User
	CharacterTag
	Vote     int
	VoteDate time.Time
}

type Rating struct {
	Id int
	User
	Rating   int
	RateDate time.Time
	*Review
}

type Review struct {
	Id int
	*Rating
	Body string
}
