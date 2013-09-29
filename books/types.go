package books

import (
	"database/sql"
	"github.com/moshee/gas"
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
		"Shōnen",
		"Shōjo",
		"Seinen",
		"Josei",
		"Kodomo",
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

func (s Sex) Scan(src interface{}) error {
	switch v := src.(type) {
	case nil:
		s = 2
		return nil

	case []byte:
		n, err := strconv.Atoi(string(v))
		if err != nil {
			return err
		}
		s = Sex(n)
		return nil
	}
	return nil
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
		"(Unknown role)",
		"Main character",
		"Secondary character",
		"Appears",
		"Cameo",
	}[t]
}

func (r CharacterRole) String() string {
	return []string{
		"(Unknown role)",
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

type Tags struct {
	Ids      pg.IntArray    `sql:"tag_ids"`
	Names    pg.StringArray `sql:"tag_names"`
	Weights  pg.IntArray    `sql:"tag_weights"`
	Spoilers pg.BoolArray   `sql:"tag_spoilers"`
}

func (self *Tags) WeightClass(i int) int {
	w := float64(self.Weights[i])
	if w < 0.0 {
		return 0
	}

	// this should give a graph with a horizontal asymptote at y = 255, with
	// y being very close to this at around x = 20. The y-intercept is very
	// close to zero.
	return int(255 * (1.0 - (3.0 / (w + 3.0))))
}

func (self *Tags) HasSpoilers() bool {
	for _, s := range self.Spoilers {
		if s {
			return true
		}
	}
	return false
}

type License struct {
	Id           int    `sql:"licensor_id"`
	Name         string `sql:"licensor_name"`
	Country      string `sql:"licensed_in"`
	DateLicensed time.Time
}

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

	*Tags
	*License
}

func (self *BookSeries) Related() (r []RelatedSeries) {
	err := gas.Query(&r, "SELECT * FROM related_series_view WHERE series_id = $1", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Related: %v", err)
		return nil
	}
	return
}

func (self *BookSeries) Characters() []Character {
	cs := make([]Character, 3)
	err := gas.Query(&cs, "SELECT * FROM series_characters WHERE series_id = $1", self.Id)
	if err != nil {
		gas.Log(gas.Warning, "BookSeries.Characters: %v", err)
		return nil
	}
	println(len(cs))
	return cs
}

func (self *BookSeries) Credits() []ProductionCredit {
	panic("unimplemented")
}

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
	SeriesId int
	Id       int    `sql:"related_id"`
	Title    string `sql:"related_title"`
	Relation SeriesRelation
}

type TranslationGroup struct {
	Id             int
	Name           string
	Summary        sql.NullString
	AvgRating      sql.NullFloat64
	AvgReleaseRate time.Duration
}

// used for scanning from releases query
type TranslationGroups struct {
	Ids   pg.IntArray    `sql:"translator_ids"`
	Names pg.StringArray `sql:"translator_names"`
}

func (self TranslationGroups) Len() int {
	return len(self.Ids)
}

func (self TranslationGroups) Less(i, j int) bool {
	return self.Ids[i] < self.Ids[j]
}

func (self TranslationGroups) Swap(i, j int) {
	self.Ids[i], self.Ids[j] = self.Ids[j], self.Ids[i]
	self.Names[i], self.Names[j] = self.Names[j], self.Names[i]
}

type Chapter struct {
	Id          int
	ReleaseDate time.Time
	*BookSeries
	Num    int
	Volume sql.NullInt64
	Notes  sql.NullString
}

// used for scanning from releases query
type Chapters struct {
	Volumes pg.IntArray `sql:"chapter_volumes"`
	Nums    pg.IntArray `sql:"chapter_nums"`
}

type Release struct {
	Id int `sql:"release_id"`
	*BookSeries
	Language      string
	ReleaseDate   time.Time
	Notes         sql.NullString `sql:"release_notes"`
	IsLastRelease bool
	Extra         sql.NullString

	*Chapters
	Padding int
	*TranslationGroups
}

type User struct {
	Id           int `sql:"user_id"`
	Email        string
	Name         string `sql:"user_name"`
	Pass         []byte
	Salt         []byte
	Privileges   `sql:"rights"`
	VoteWeight   int
	Summary      sql.NullString `sql:"user_summary"`
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

// for templates, since they can't refer to constants defined in code here
func (self *User) IsBanned() bool        { return self.Privileges.Is(Banned) }
func (self *User) IsAdministrator() bool { return self.Privileges.Is(Administrator) }
func (self *User) IsModerator() bool     { return self.Privileges.Is(Moderator) }
func (self *User) IsContributor() bool   { return self.Privileges.Is(Contributor) }
func (self *User) IsDeveloper() bool     { return self.Privileges.Is(Developer) }

func (self *User) OwnedChapters() []OwnedChapter {
	panic("unimplemented")
}

func (self *User) Online() bool {
	panic("unimplemented")
}

// interface gas.User
func (self *User) Allowed(privileges interface{}) bool {
	return self.Privileges.Is(privileges.(Privileges))
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
	Id          int `sql:"character_id"`
	Name        string
	NativeName  string
	Aliases     pg.StringArray
	Nationality string
	Birthday    time.Time
	Sex
	Weight int
	Height int
	Sizes  string
	BloodType
	Description string
	Picture     bool

	// only valid for the series it's being queried for
	SeriesId      int
	CharacterType `sql:"type"`
	CharacterRole `sql:"role"`
}

func (self *Character) Age() int {
	return 0
}

func (self *Character) IsMain() bool {
	return self.CharacterType == 1
}

func (self *Character) CastIn() []CharacterAppearance {
	panic("unimplemented")
}

type CharacterAppearance struct {
	Id int
	*Character
	*BookSeries
	CharacterType `sql:"type"`
	CharacterRole `sql:"role"`
	Appearances   pg.IntArray
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
	Id int `sql:"post_id"`
	*User
	Category   string
	DatePosted time.Time
	Title      string
	Body       string
}

var Langs = map[string]string{
	"aa": "Afar", "ab": "Abkhazian", "af": "Afrikaans",
	"ak": "Akan", "sq": "Albanian", "am": "Amharic",
	"ar": "Arabic", "an": "Aragonese", "hy": "Armenian",
	"as": "Assamese", "av": "Avaric", "ae": "Avestan",
	"ay": "Aymara", "az": "Azerbaijani", "ba": "Bashkir",
	"bm": "Bambara", "eu": "Basque", "be": "Belarusian",
	"bn": "Bengali", "bh": "Bihari languages", "bi": "Bislama",
	"bs": "Bosnian", "br": "Breton", "bg": "Bulgarian",
	"my": "Burmese", "ca": "Catalan", "ch": "Chamorro",
	"ce": "Chechen", "zh": "Chinese", "cu": "Church Slavic",
	"cv": "Chuvash", "kw": "Cornish", "co": "Corsican",
	"cr": "Cree", "cs": "Czech", "da": "Danish",
	"dv": "Divehi", "nl": "Dutch", "dz": "Dzongkha",
	"en": "English", "eo": "Esperanto", "et": "Estonian",
	"ee": "Ewe", "fo": "Faroese", "fj": "Fijian",
	"fi": "Finnish", "fr": "French", "fy": "Western Frisian",
	"ff": "Fulah", "ka": "Georgian", "de": "German",
	"gd": "Gaelic", "ga": "Irish", "gl": "Galician",
	"gv": "Manx", "el": "Greek", "gn": "Guarani",
	"gu": "Gujarati", "ht": "Haitian", "ha": "Hausa",
	"he": "Hebrew", "hz": "Herero", "hi": "Hindi",
	"ho": "Hiri Motu", "hr": "Croatian", "hu": "Hungarian",
	"ig": "Igbo", "is": "Icelandic", "io": "Ido",
	"ii": "Yi", "iu": "Inuktitut", "ie": "Interlingue",
	"ia": "Interlingua", "id": "Indonesian", "ik": "Inupiaq",
	"it": "Italian", "jv": "Javanese", "ja": "Japanese",
	"kl": "Kalaallisut", "kn": "Kannada", "ks": "Kashmiri",
	"kr": "Kanuri", "kk": "Kazakh", "km": "Central Khmer",
	"ki": "Kikuyu", "rw": "Kinyarwanda", "ky": "Kirghiz",
	"kv": "Komi", "kg": "Kongo", "ko": "Korean",
	"kj": "Kuanyama", "ku": "Kurdish", "lo": "Lao",
	"la": "Latin", "lv": "Latvian", "li": "Limburgan",
	"ln": "Lingala", "lt": "Lithuanian", "lb": "Luxembourgish",
	"lu": "Luba-Katanga", "lg": "Ganda", "mk": "Macedonian",
	"mh": "Marshallese", "ml": "Malayalam", "mi": "Maori",
	"mr": "Marathi", "ms": "Malay", "mg": "Malagasy",
	"mt": "Maltese", "mn": "Mongolian", "na": "Nauru",
	"nv": "Navajo", "nr": "South Ndebele", "nd": "North Ndebele",
	"ng": "Ndonga", "ne": "Nepali", "nn": "Norwegian (Nynorsk)",
	"nb": "Norwegian (Bokmål)", "no": "Norwegian", "ny": "Chichewa",
	"oc": "Occitan", "oj": "Ojibwa", "or": "Oriya",
	"om": "Oromo", "os": "Ossetian", "pa": "Panjabi",
	"fa": "Persian", "pi": "Pali", "pl": "Polish",
	"pt": "Portuguese", "ps": "Pushto", "qu": "Quechua",
	"rm": "Romansh", "ro": "Romanian", "rn": "Rundi",
	"ru": "Russian", "sg": "Sango", "sa": "Sanskrit",
	"si": "Sinhala", "sk": "Slovak", "sl": "Slovenian",
	"se": "Northern Sami", "sm": "Samoan", "sn": "Shona",
	"sd": "Sindhi", "so": "Somali", "st": "Southern Sotho",
	"es": "Spanish", "sc": "Sardinian", "sr": "Serbian",
	"ss": "Swati", "su": "Sundanese", "sw": "Swahili",
	"sv": "Swedish", "ty": "Tahitian", "ta": "Tamil",
	"tt": "Tatar", "te": "Telugu", "tg": "Tajik",
	"tl": "Tagalog", "th": "Thai", "bo": "Tibetan",
	"ti": "Tigrinya", "to": "Tonga", "tn": "Tswana",
	"ts": "Tsonga", "tk": "Turkmen", "tr": "Turkish",
	"tw": "Twi", "ug": "Uighur", "uk": "Ukrainian",
	"ur": "Urdu", "uz": "Uzbek", "ve": "Venda",
	"vi": "Vietnamese", "vo": "Volapük", "cy": "Welsh",
	"wa": "Walloon", "wo": "Wolof", "xh": "Xhosa",
	"yi": "Yiddish", "yo": "Yoruba", "za": "Zhuang",
	"zu": "Zulu",
}

var Countries = map[string]string{
	"AF": "Afghanistan", "AX": "Åland Islands", "AL": "Albania",
	"DZ": "Algeria", "AS": "American Samoa", "AD": "Andorra",
	"AO": "Angola", "AI": "Anguilla", "AQ": "Antarctica",
	"AG": "Antigua And Barbuda", "AR": "Argentina", "AM": "Armenia",
	"AW": "Aruba", "AU": "Australia", "AT": "Austria",
	"AZ": "Azerbaijan", "BS": "Bahamas", "BH": "Bahrain",
	"BD": "Bangladesh", "BB": "Barbados", "BY": "Belarus",
	"BE": "Belgium", "BZ": "Belize", "BJ": "Benin",
	"BM": "Bermuda", "BT": "Bhutan", "BO": "Plurinational State Of Bolivia",
	"BQ": "Sint Eustatius And Saba Bonaire", "BA": "Bosnia And Herzegovina", "BW": "Botswana",
	"BV": "Bouvet Island", "BR": "Brazil", "IO": "British Indian Ocean Territory",
	"BN": "Brunei Darussalam", "BG": "Bulgaria", "BF": "Burkina Faso",
	"BI": "Burundi", "KH": "Cambodia", "CM": "Cameroon",
	"CA": "Canada", "CV": "Cape Verde", "KY": "Cayman Islands",
	"CF": "Central African Republic", "TD": "Chad", "CL": "Chile",
	"CN": "China", "CX": "Christmas Island", "CC": "Cocos (Keeling) Islands",
	"CO": "Colombia", "KM": "Comoros", "CG": "Congo",
	"CD": "The Democratic Republic Of The Congo", "CK": "Cook Islands", "CR": "Costa Rica",
	"CI": "Côte D'Ivoire", "HR": "Croatia", "CU": "Cuba",
	"CW": "CuraçaO", "CY": "Cyprus", "CZ": "Czech Republic",
	"DK": "Denmark", "DJ": "Djibouti", "DM": "Dominica",
	"DO": "Dominican Republic", "EC": "Ecuador", "EG": "Egypt",
	"SV": "El Salvador", "GQ": "Equatorial Guinea", "ER": "Eritrea",
	"EE": "Estonia", "ET": "Ethiopia", "FK": "Falkland Islands (Malvinas)",
	"FO": "Faroe Islands", "FJ": "Fiji", "FI": "Finland",
	"FR": "France", "GF": "French Guiana", "PF": "French Polynesia",
	"TF": "French Southern Territories", "GA": "Gabon", "GM": "Gambia",
	"GE": "Georgia", "DE": "Germany", "GH": "Ghana",
	"GI": "Gibraltar", "GR": "Greece", "GL": "Greenland",
	"GD": "Grenada", "GP": "Guadeloupe", "GU": "Guam",
	"GT": "Guatemala", "GG": "Guernsey", "GN": "Guinea",
	"GW": "Guinea-Bissau", "GY": "Guyana", "HT": "Haiti",
	"HM": "Heard Island And Mcdonald Islands", "VA": "Holy See (Vatican City State)", "HN": "Honduras",
	"HK": "Hong Kong", "HU": "Hungary", "IS": "Iceland",
	"IN": "India", "ID": "Indonesia", "IR": "Islamic Republic Of Iran",
	"IQ": "Iraq", "IE": "Ireland", "IM": "Isle Of Man",
	"IL": "Israel", "IT": "Italy", "JM": "Jamaica",
	"JP": "Japan", "JE": "Jersey", "JO": "Jordan",
	"KZ": "Kazakhstan", "KE": "Kenya", "KI": "Kiribati",
	"KP": "Democratic People's Republic Of Korea", "KR": "Republic Of Korea", "KW": "Kuwait",
	"KG": "Kyrgyzstan", "LA": "Lao People's Democratic Republic", "LV": "Latvia",
	"LB": "Lebanon", "LS": "Lesotho", "LR": "Liberia",
	"LY": "Libya", "LI": "Liechtenstein", "LT": "Lithuania",
	"LU": "Luxembourg", "MO": "Macao", "MK": "The Former Yugoslav Republic Of Macedonia",
	"MG": "Madagascar", "MW": "Malawi", "MY": "Malaysia",
	"MV": "Maldives", "ML": "Mali", "MT": "Malta",
	"MH": "Marshall Islands", "MQ": "Martinique", "MR": "Mauritania",
	"MU": "Mauritius", "YT": "Mayotte", "MX": "Mexico",
	"FM": "Federated States Of Micronesia", "MD": "Republic Of Moldova", "MC": "Monaco",
	"MN": "Mongolia", "ME": "Montenegro", "MS": "Montserrat",
	"MA": "Morocco", "MZ": "Mozambique", "MM": "Myanmar",
	"NA": "Namibia", "NR": "Nauru", "NP": "Nepal",
	"NL": "Netherlands", "NC": "New Caledonia", "NZ": "New Zealand",
	"NI": "Nicaragua", "NE": "Niger", "NG": "Nigeria",
	"NU": "Niue", "NF": "Norfolk Island", "MP": "Northern Mariana Islands",
	"NO": "Norway", "OM": "Oman", "PK": "Pakistan",
	"PW": "Palau", "PS": "State Of Palestine", "PA": "Panama",
	"PG": "Papua New Guinea", "PY": "Paraguay", "PE": "Peru",
	"PH": "Philippines", "PN": "Pitcairn", "PL": "Poland",
	"PT": "Portugal", "PR": "Puerto Rico", "QA": "Qatar",
	"RE": "RÉUNION", "RO": "Romania", "RU": "Russian Federation",
	"RW": "Rwanda", "BL": "Saint BARTHÉLEMY", "SH": "Ascension And Tristan Da Cunha Saint Helena",
	"KN": "Saint Kitts And Nevis", "LC": "Saint Lucia", "MF": "Saint Martin (French Part)",
	"PM": "Saint Pierre And Miquelon", "VC": "Saint Vincent And The Grenadines", "WS": "Samoa",
	"SM": "San Marino", "ST": "Sao Tome And Principe", "SA": "Saudi Arabia",
	"SN": "Senegal", "RS": "Serbia", "SC": "Seychelles",
	"SL": "Sierra Leone", "SG": "Singapore", "SX": "Sint Maarten (Dutch Part)",
	"SK": "Slovakia", "SI": "Slovenia", "SB": "Solomon Islands",
	"SO": "Somalia", "ZA": "South Africa", "GS": "South Georgia And The South Sandwich Islands",
	"SS": "South Sudan", "ES": "Spain", "LK": "Sri Lanka",
	"SD": "Sudan", "SR": "Suriname", "SJ": "Svalbard And Jan Mayen",
	"SZ": "Swaziland", "SE": "Sweden", "CH": "Switzerland",
	"SY": "Syrian Arab Republic", "TW": "Province Of China Taiwan", "TJ": "Tajikistan",
	"TZ": "United Republic Of Tanzania", "TH": "Thailand", "TL": "Timor-Leste",
	"TG": "Togo", "TK": "Tokelau", "TO": "Tonga",
	"TT": "Trinidad And Tobago", "TN": "Tunisia", "TR": "Turkey",
	"TM": "Turkmenistan", "TC": "Turks And Caicos Islands", "TV": "Tuvalu",
	"UG": "Uganda", "UA": "Ukraine", "AE": "United Arab Emirates",
	"GB": "United Kingdom", "US": "United States", "UM": "United States Minor Outlying Islands",
	"UY": "Uruguay", "UZ": "Uzbekistan", "VU": "Vanuatu",
	"VE": "Bolivarian Republic Of Venezuela", "VN": "Viet Nam", "VG": "British Virgin Islands",
	"VI": "U.S. Virgin Islands", "WF": "Wallis And Futuna", "EH": "Western Sahara",
	"YE": "Yemen", "ZM": "Zambia", "ZW": "Zimbabwe",
}
