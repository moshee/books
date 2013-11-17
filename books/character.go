package books

import (
	pg "github.com/moshee/pgtypes"
	"time"
)

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

func (self *Character) IsMain() bool {
	return self.CharacterType == 1
}

func (self *Character) CastIn() []CharacterAppearance {
	panic("unimplemented")
}

type Characters []Character

func (self Characters) Mains() (cs Characters) {
	cs = make(Characters, 0)

	for _, c := range self {
		if c.IsMain() {
			cs = append(cs, c)
		}
	}

	return
}

func (self Characters) Others() (cs Characters) {
	cs = make(Characters, 0)

	for _, c := range self {
		if !c.IsMain() {
			cs = append(cs, c)
		}
	}

	return
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

type (
	BloodType         int
	CharacterType     int
	CharacterRole     int
	CharacterRelation int
)

func (t CharacterType) String() string {
	return []string{
		"(Unknown role)",
		"Main",
		"Supporting",
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
