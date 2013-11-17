package books

import (
	"database/sql"
	"time"
)

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
