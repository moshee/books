package books

import (
	"bytes"
	"github.com/moshee/gas"
	"html/template"
	"time"
)

type Feed struct {
	Id          int
	Kind        string
	Hash        []byte
	Spec        string
	Creator     *User
	Title       string
	Description string
	DateCreated time.Time

	Items interface{}
}

// Execute the feed's associated template and return the output as safe HTML
func (self *Feed) Render() template.HTML {
	t := gas.Templates["books"].Lookup("feed-" + self.Kind)
	if t == nil {
		return template.HTML("Error rendering feed '" + self.Title + "': no template found for '" + self.Kind + "'")
	}

	buf := new(bytes.Buffer)
	err := t.Execute(buf, self.Items)
	if err != nil {
		return template.HTML("Error rendering for feed '" + self.Title + "': " + err.Error())
	}

	return template.HTML(buf.Bytes())
}

// Query data using the feedspec and populate the Items field so that Render
// can be used
func (self *Feed) Populate() error {

	return nil
}
