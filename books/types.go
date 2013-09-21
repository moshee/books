package books

import (
	"database/sql"
	// "github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"sort"
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
	Privileges        int
	ReadStatus        int
	BloodType         int
	CharacterType     int
	CharacterRole     int
	CharacterRelation int
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
		"Shounen",
		"Shoujo",
		"Seinen",
		"Josei",
		"Kodomomuke",
		"Seijin",
	}[d]
}

func (s Sex) String() string {
	return []string{
		"Male",
		"Female",
		"Other",
	}[s]
}

const (
	Scenario Credit = 1 << iota
	Art
)

func (c Credit) String() string {
	cs := make([]string, 0, 4)
	if c&Scenario != 0 {
		cs = append(cs, "Story")
	}
	if c&Art != 0 {
		cs = append(cs, "Art")
	}
	return strings.Join(cs, ", ")
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

const (
	Banned Privileges = 1 << iota
	Administrator
	Moderator
	Contributor
	Developer
)

func (self Privileges) String() string {
	if self.Is(Developer) {
		return "Developer"
	}
	if self.Is(Contributor) {
		return "Contributor"
	}
	if self.Is(Moderator) {
		return "Moderator"
	}
	if self.Is(Administrator) {
		return "Administrator"
	}
	if self.Is(Banned) {
		return "Banned"
	}
	return ""
}

func (self Privileges) Is(other Privileges) bool {
	return self&other != 0
}

func (self Privileges) Isnt(other Privileges) bool {
	return self&other == 0
}

func (s ReadStatus) String() string {
	return []string{
		"Read it",
		"Have it",
		"Skipped it",
	}[s]
}

func (t CharacterType) String() string {
	return []string{
		"Main character",
		"Secondary character",
		"Appears",
		"Cameo",
	}[t]
}

func (r CharacterRole) String() string {
	return []string{
		"Antagonist",
		"Antihero",
		"Archenemy",
		"Characterization",
		"False protagonist",
		"Foil",
		"Protagonist",
		"Stock",
		"Supporting",
		"Narrator",
	}[r]
}

func (r CharacterRelation) String() string {
	return []string{
		"Family",
		"Friend",
		"Enemy",
		"Love interest",
		"Lover",
	}[r]
}

func (t BloodType) String() string {
	return []string{
		"O",
		"A",
		"B",
		"AB",
	}[t]
}

type Publisher struct {
	Id        int
	Name      string
	DateAdded time.Time
	Summary   sql.NullString
}

type Magazine struct {
	Id    int
	Title string
	*Publisher
	DateAdded time.Time
	Summary   sql.NullString
}

type BookSeries struct {
	Id          int
	Title       string
	NativeTitle string
	OtherTitles pg.StringArray
	SeriesKind
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

	Tags pg.StringArray
}

func (self *BookSeries) Related() []RelatedSeries {
	return nil
}

func (self *BookSeries) Credits() []ProductionCredit {
	panic("unimplemented")
}

func (self *BookSeries) RatingStars() []string {
	if !self.AvgRating.Valid {
		return nil
	}

	s := make([]string, 5)
	round_max := self.AvgRating.Float64 + 0.5

	n := 0.0
	for i := range s {
		if n < round_max {
			s[i] = "on"
		} else {
			s[i] = "off"
		}
		n += 1.0
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
	Related  *BookSeries
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
	ReleaseDate time.Time
	*BookSeries
	Num    int
	Volume sql.NullInt64
	Notes  sql.NullString
}

type Chapters []*Chapter

// create a representation of the list of chapters with ranges, using display
// names as necessary
func (self Chapters) String() string {
	panic("unimplemented")
}

type Release struct {
	Id int
	*BookSeries
	*TranslationGroup
	*TranslationProject
	Language      string
	ReleaseDate   time.Time
	Notes         sql.NullString
	IsLastRelease bool
	Volume        sql.NullInt64
	Extra         sql.NullString

	Chapters pg.IntArray
}

func (self *Release) ChapterRange() string {
	switch len(self.Chapters) {
	case 0:
		return ""
	case 1:
		return strconv.Itoa(self.Chapters[0])
	}
	sort.Ints(self.Chapters)

	var (
		this  = self.Chapters[1]
		last  = self.Chapters[0]
		lower = last
		upper = last
		out   = make([]string, 0)
	)
	for _, this = range self.Chapters[1:] {
		switch this - last {
		case 0:
			continue
		case 1:
			upper = this
			last = this
			continue
		}
		// not consecutive
		s := strconv.Itoa(lower)
		if lower != upper {
			s += "-" + strconv.Itoa(upper)
		}
		out = append(out, s)
		upper = this
		lower = this
		last = this
	}
	s := strconv.Itoa(lower)
	if lower != upper {
		s += "-" + strconv.Itoa(upper)
	}
	out = append(out, s)

	return strings.Join(out, ", ")
}

type TranslationProject struct {
	Id int
	*BookSeries
	StartDate time.Time
	EndDate   time.Time
}

func (self *TranslationProject) Members() []*User {
	panic("unimplemented")
}

type User struct {
	Id    int
	Email string
	Name  string
	Pass  []byte
	Salt  []byte
	Privileges
	VoteWeight   int
	Summary      sql.NullString
	RegisterDate time.Time
	LastActive   time.Time
	Avatar       bool

	// Not to be confused with Online(), Active indicates whether or not the
	// user is an activated user on the site (has their activation email been
	// sent yet, etc.). May be used for other purposes later such as banning.
	Active bool
}

func (self *User) AvatarFile() string {
	if self.Avatar {
		return "u" + strconv.Itoa(self.Id) + ".jpg"
	} else {
		return ""
	}
}

func (self *User) OwnedChapters() []OwnedChapter {
	panic("unimplemented")
}

func (self *User) Online() bool {
	panic("unimplemented")
}

type OwnedChapter struct {
	Id int
	*User
	*Chapter
	ReadStatus
	Date time.Time
}

type OwnedRelease struct {
	Id int
	*User
	*Release
	ReadStatus
	Date time.Time
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

func (self *Character) CastIn() []CharacterAppearance {
	panic("unimplemented")
}

type CharacterAppearance struct {
	*Character
	*BookSeries
	CharacterType
	CharacterRole
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

type BookTag struct {
	Id int
	*BookSeries
	Name    string
	Spoiler bool
	Weight  int
}

type BookTagConsensus struct {
	Id int
	User
	*BookTag
	Vote     int
	VoteDate time.Time
}

type CharacterTag struct {
	Id int
	*Character
	Name    string
	Spoiler bool
	Weight  int
}

type CharacterTagConsensus struct {
	Id int
	*User
	*CharacterTag
	Vote     int
	VoteDate time.Time
}

type BookRating struct {
	Id int
	*User
	*BookSeries
	Rating   int
	Review   sql.NullString
	RateDate time.Time
}

type TranslatorRating struct {
	Id int
	*User
	*TranslationGroup
	Rating   int
	Review   sql.NullString
	RateDate time.Time
}

type NewsPost struct {
	Id int
	*User
	Category   string
	DatePosted time.Time
	Title      string
	Body       string
}

var Langs = map[string]string{
	"aa": "Afar",
	"ab": "Abkhazian",
	"af": "Afrikaans",
	"ak": "Akan",
	"sq": "Albanian",
	"am": "Amharic",
	"ar": "Arabic",
	"an": "Aragonese",
	"hy": "Armenian",
	"as": "Assamese",
	"av": "Avaric",
	"ae": "Avestan",
	"ay": "Aymara",
	"az": "Azerbaijani",
	"ba": "Bashkir",
	"bm": "Bambara",
	"eu": "Basque",
	"be": "Belarusian",
	"bn": "Bengali",
	"bh": "Bihari languages",
	"bi": "Bislama",
	"bs": "Bosnian",
	"br": "Breton",
	"bg": "Bulgarian",
	"my": "Burmese",
	"ca": "Catalan",
	"ch": "Chamorro",
	"ce": "Chechen",
	"zh": "Chinese",
	"cu": "Church Slavic",
	"cv": "Chuvash",
	"kw": "Cornish",
	"co": "Corsican",
	"cr": "Cree",
	"cs": "Czech",
	"da": "Danish",
	"dv": "Divehi",
	"nl": "Dutch",
	"dz": "Dzongkha",
	"en": "English",
	"eo": "Esperanto",
	"et": "Estonian",
	"ee": "Ewe",
	"fo": "Faroese",
	"fj": "Fijian",
	"fi": "Finnish",
	"fr": "French",
	"fy": "Western Frisian",
	"ff": "Fulah",
	"ka": "Georgian",
	"de": "German",
	"gd": "Gaelic",
	"ga": "Irish",
	"gl": "Galician",
	"gv": "Manx",
	"el": "Greek",
	"gn": "Guarani",
	"gu": "Gujarati",
	"ht": "Haitian",
	"ha": "Hausa",
	"he": "Hebrew",
	"hz": "Herero",
	"hi": "Hindi",
	"ho": "Hiri Motu",
	"hr": "Croatian",
	"hu": "Hungarian",
	"ig": "Igbo",
	"is": "Icelandic",
	"io": "Ido",
	"ii": "Yi",
	"iu": "Inuktitut",
	"ie": "Interlingue",
	"ia": "Interlingua",
	"id": "Indonesian",
	"ik": "Inupiaq",
	"it": "Italian",
	"jv": "Javanese",
	"ja": "Japanese",
	"kl": "Kalaallisut",
	"kn": "Kannada",
	"ks": "Kashmiri",
	"kr": "Kanuri",
	"kk": "Kazakh",
	"km": "Central Khmer",
	"ki": "Kikuyu",
	"rw": "Kinyarwanda",
	"ky": "Kirghiz",
	"kv": "Komi",
	"kg": "Kongo",
	"ko": "Korean",
	"kj": "Kuanyama",
	"ku": "Kurdish",
	"lo": "Lao",
	"la": "Latin",
	"lv": "Latvian",
	"li": "Limburgan",
	"ln": "Lingala",
	"lt": "Lithuanian",
	"lb": "Luxembourgish",
	"lu": "Luba-Katanga",
	"lg": "Ganda",
	"mk": "Macedonian",
	"mh": "Marshallese",
	"ml": "Malayalam",
	"mi": "Maori",
	"mr": "Marathi",
	"ms": "Malay",
	"mg": "Malagasy",
	"mt": "Maltese",
	"mn": "Mongolian",
	"na": "Nauru",
	"nv": "Navajo",
	"nr": "South Ndebele",
	"nd": "North Ndebele",
	"ng": "Ndonga",
	"ne": "Nepali",
	"nn": "Norwegian (Nynorsk)",
	"nb": "Norwegian (Bokmål)",
	"no": "Norwegian",
	"ny": "Chichewa",
	"oc": "Occitan",
	"oj": "Ojibwa",
	"or": "Oriya",
	"om": "Oromo",
	"os": "Ossetian",
	"pa": "Panjabi",
	"fa": "Persian",
	"pi": "Pali",
	"pl": "Polish",
	"pt": "Portuguese",
	"ps": "Pushto",
	"qu": "Quechua",
	"rm": "Romansh",
	"ro": "Romanian",
	"rn": "Rundi",
	"ru": "Russian",
	"sg": "Sango",
	"sa": "Sanskrit",
	"si": "Sinhala",
	"sk": "Slovak",
	"sl": "Slovenian",
	"se": "Northern Sami",
	"sm": "Samoan",
	"sn": "Shona",
	"sd": "Sindhi",
	"so": "Somali",
	"st": "Southern Sotho",
	"es": "Spanish",
	"sc": "Sardinian",
	"sr": "Serbian",
	"ss": "Swati",
	"su": "Sundanese",
	"sw": "Swahili",
	"sv": "Swedish",
	"ty": "Tahitian",
	"ta": "Tamil",
	"tt": "Tatar",
	"te": "Telugu",
	"tg": "Tajik",
	"tl": "Tagalog",
	"th": "Thai",
	"bo": "Tibetan",
	"ti": "Tigrinya",
	"to": "Tonga",
	"tn": "Tswana",
	"ts": "Tsonga",
	"tk": "Turkmen",
	"tr": "Turkish",
	"tw": "Twi",
	"ug": "Uighur",
	"uk": "Ukrainian",
	"ur": "Urdu",
	"uz": "Uzbek",
	"ve": "Venda",
	"vi": "Vietnamese",
	"vo": "Volapük",
	"cy": "Welsh",
	"wa": "Walloon",
	"wo": "Wolof",
	"xh": "Xhosa",
	"yi": "Yiddish",
	"yo": "Yoruba",
	"za": "Zhuang",
	"zu": "Zulu",
}
