package books

import (
	"database/sql"
	pg "github.com/moshee/pgtypes"
	"time"
)

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
	Permalink     sql.NullString

	*Chapters
	Padding int
	*TranslationGroups
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
