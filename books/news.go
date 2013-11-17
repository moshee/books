package books

import (
	"time"
)

type NewsPost struct {
	Id int `sql:"post_id"`
	*User
	Category   string
	DatePosted time.Time
	Title      string
	Body       string
}
