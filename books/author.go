package books

import (
	"database/sql"
	"github.com/moshee/gas"
	pg "github.com/moshee/pgtypes"
	"strconv"
	"strings"
	"time"
)

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
	SeriesId  int
	AuthorId  int
	GivenName string
	Surname   sql.NullString
	Credit
}

type LinkKind struct {
	Id   int
	Name string
}

type Link struct {
	LinkKind
	URL string
}

type (
	Sex    int
	Credit int
)

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

// Controllers

func AuthorsIndex(g *gas.Gas) {

}

func AuthorPage(g *gas.Gas) {

}
