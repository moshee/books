package books

import (
	"bytes"
	"github.com/moshee/gas"
	"html/template"
)

type Feed struct {
	Title string
	Id    string
	Owner *User
	Items []FeedItem
}

func (self *Feed) Render(i int) template.HTML {
	name := self.Items[i].Template()
	t := gas.Templates["books"].Lookup(name)
	if t == nil {
		return template.HTML("Error rendering template: no template found for '" + name + "' in feed '" + self.Title + "'")
	}

	buf := new(bytes.Buffer)
	err := t.Execute(buf, self.Items[i])
	if err != nil {
		return template.HTML("Error rendering template for feed '" + self.Title + "': " + err.Error())
	}

	return template.HTML(buf.Bytes())
}

type FeedItem interface {
	Template() string
}

func (Release) Template() string { return "feed-release" }
