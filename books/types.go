package books

import (
	"html/template"
)

type Error struct {
	Code    int // http code
	Message string
}

func (e Error) Error() string {
	return e.Message
}

var (
	ErrBadPassword         = Error{401, "Invalid username or password."}
	ErrUserBanned          = Error{401, "You are banned. Go away."}
	ErrAccountNotActivated = Error{401, "Your account has not been activated yet. <a id=send-activation href=/activate>Click here</a> to resend the activation e-mail if you need to."}
)

type AJAXResponse struct {
	Ok      bool   `json:"ok"`
	Message string `json:"msg"`
}

// Banner is used for showing notices, etc. on pages
type Banner struct {
	Kind  string        `json:"kind"`
	Title template.HTML `json:"title"`
	Body  template.HTML `json:"body"`
}

func newBanner(kind, title, body string) *Banner {
	return &Banner{
		Kind:  kind,
		Title: template.HTML(title),
		Body:  template.HTML(body),
	}
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
