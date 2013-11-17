package books

import (
	"database/sql"
	pg "github.com/moshee/pgtypes"
	"time"
)

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
