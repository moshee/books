package books

import (
	"database/sql"
	"errors"
	"github.com/moshee/gas"
	"time"
	"unicode"
)

type User struct {
	Id           int    `json:"id,omitempty" sql:"user_id"`
	Email        string `json:"email,omitempty"`
	Name         string `json:"name,omitempty" sql:"user_name"`
	Pass         []byte `json:"-"`
	Salt         []byte `json:"-"`
	Privileges   `json:"privs,omitempty" sql:"rights"`
	VoteWeight   int            `json:"vote_weight,omitempty"`
	Summary      sql.NullString `json:"summary,omitempty" sql:"user_summary"`
	RegisterDate time.Time      `json:"register_date,omitempty"`
	LastActive   time.Time      `json:"last_active,omitempty"`
	Avatar       sql.NullString `json:"avatar,omitempty"`

	// Not to be confused with Online(), Active indicates whether or not the
	// user is an activated user on the site (has their activation email been
	// sent yet, etc.). May be used for other purposes later such as banning.
	Active bool `json:"-"`

	Hash       string
	ActivateBy time.Time
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

func (self *User) Feeds() []Feed {
	return nil
}

// interface gas.User
func (self *User) Allowed(privileges interface{}) bool {
	return self.Privileges.Is(privileges.(Privileges))
}

type (
	ReadStatus int
	Privileges int
)

func (s ReadStatus) String() string {
	return []string{
		"Read it",
		"Have it",
		"Skipped it",
	}[s]
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

// Controllers

func Signup(g *gas.Gas) {
	if user := g.User().(*User); user != nil {
		g.Reroute("/", 302, newBanner("friendly", "You already have an account!", "We're flattered that you like the site so much that you need <strong>another</strong> account, but just one will be enough."))
		return
	}
	g.Render("books", "signup", nil)
}

func Login(g *gas.Gas) {
	if user := g.User().(*User); user != nil {
		g.Reroute("/", 302, newBanner("friendly", "You're already logged in!", ""))
		return
	}

	var data map[string]string

	if rr := g.RerouteInfo; rr != nil {
		if err := rr.Recover(&data); err != nil {
			gas.Log(gas.Warning, "books login reroute: %v", err)
		}
	}

	g.Render("books", "login", data["location"])
}

func UserProfile(g *gas.Gas) {
	id, err := g.IntArg("id")
	if err != nil {
		g.Error(400, err)
		return
	}

	me := g.User().(*User)

	them := new(User)
	g.Populate(them, "SELECT * FROM books.users WHERE id = $1", id)

	reviews := make([]BookRating, 0, 3)

	g.Populate(&reviews, `
		SELECT
			r.id,
			r.user_id,
			r.series_id,
			s.title,
			r.rating,
			r.review,
			r.rate_date
		FROM
			books.book_ratings r,
			books.book_series s
		WHERE r.user_id = $1
		  AND s.id = r.series_id
		  AND r.review IS NOT NULL
		ORDER BY r.rate_date DESC
		LIMIT 3
		`, them.Id)

	g.Render("books", "user-profile", &struct {
		User    *User
		Them    *User
		Reviews []BookRating
	}{
		me,
		them,
		reviews,
	})
}

func SettingsProfile(g *gas.Gas) {
	g.Render("books", "user-settings-profile", &struct {
		User *User
	}{
		g.User().(*User),
	})
}

func SettingsFeeds(g *gas.Gas) {
	var feeds []Feed

	user := g.User().(*User)

	g.Populate(&feeds, `
		SELECT
			feeds.id,
			feeds.input_kind,
			feeds.output_kind,
			feeds.ref,
			feeds.include,
			feeds.exclude,
			users.id,
			users.name,
			feeds.title,
			feeds.description,
			feeds.date_created
		FROM
			books.feeds,
			books.users
		WHERE feeds.creator = users.id
		  AND users.id = $1
		ORDER BY feeds.date_created DESC
		`, user.Id)

	g.Render("books", "user-settings-feeds", &struct {
		User  *User
		Feeds []Feed
	}{
		user,
		feeds,
	})
}

func SettingsAccount(g *gas.Gas) {
	g.Render("books", "user-settings-account", &struct {
		User *User
	}{
		g.User().(*User),
	})
}

func PostLogin(g *gas.Gas) {
	if err := g.SignIn(); err != nil {

		if booksError, ok := err.(Error); ok {
			g.WriteHeader(booksError.Code)
			g.JSON(&AJAXResponse{false, booksError.Message})
		} else {
			g.WriteHeader(400)
			g.JSON(&AJAXResponse{false, err.Error()})
			// TODO: gas.Log(gas.Warning, "books: Login: %v", err)
			// TODO: g.JSON(&AJAXResponse{false, "There was an error creating your session. This error has been logged. Please try again later or complain about it."}
		}
		return
	}

	user := g.User().(*User)

	if user == nil {
		gas.Log(gas.Warning, "books: Login: user is nil")
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, "There was an error logging you in. This error has been logged. Please try again later or complain on <a href=\"https://github.com/moshee/books/issues\">the issue tracker</a>."})
		return
	}

	gas.DB.Exec("UPDATE books.users SET last_active = now() WHERE id = $1", user.Id)

	g.Render("books", "user-cp", user)
	if page := g.FormValue("page"); len(page) > 0 {
		g.Render("books", "cp-"+page, user)
	}
}

func Logout(g *gas.Gas) {
	if err := g.SignOut(); err != nil {
		g.WriteHeader(400)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	g.Render("books", "user-cp", nil)
}

var (
	errUsernameEmpty        = errors.New("I'm sorry, did you type in a username? I don't see it.")
	errUsernameInvalidChars = errors.New("Let's stick to normal letters, shall we? I'll take _ - ' ` as well.")
	errUsernameTooLong      = errors.New("How do you expect me to remember a name that long? Let's keep it to 30 characters or less.")
	errUsernameNoLetters    = errors.New("Is a single letter in there too much to ask?")
	errUsernameTaken        = "I already know someone called <NAME>. Got another name I can use so I don't get confused?"
	validRanges             = []*unicode.RangeTable{
		unicode.Letter,
		unicode.Digit,
	}
	validChars = []rune{'_', '-', '\'', '`'}
)

func validateUsername(name string) error {
	length := len(name)
	switch {
	case length == 0:
		return errUsernameEmpty
	case length > 30:
		return errUsernameTooLong
	}

	anyLetters := false

	for _, ch := range name {
		ok := false
		for _, valid := range validChars {
			if ch == valid {
				ok = true
				break
			}
		}
		if !ok {
			if !unicode.IsOneOf(validRanges, ch) {
				return errUsernameInvalidChars
			}
			anyLetters = true
		}
	}

	if !anyLetters {
		return errUsernameNoLetters
	}

	return nil
}

func ValidateUsername(g *gas.Gas) {
	name := g.FormValue("username")
	if err := validateUsername(name); err != nil {
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	id := -1
	gas.DB.QueryRow("SELECT id FROM books.users WHERE name = $1", name).Scan(&id)
	if id > 0 {
		g.JSON(&AJAXResponse{false, errUsernameTaken})
		return
	}

	if len(name) <= 3 {
		g.JSON(&AJAXResponse{true, "You sure lucked out with a name like that, <NAME>."})
	} else {
		g.JSON(&AJAXResponse{true, "<NAME>, is it? Nice to meet you."})
	}
}

func PostSignup(g *gas.Gas) {
	// server-side form validation in addition to  client-side, because who knows
	errs := make(map[string]string)

	// need this for multiple form values or something?
	g.ParseMultipartForm(0)

	name := g.FormValue("username")
	if err := validateUsername(name); err != nil {
		errs["username"] = err.Error()
	}

	email := g.FormValue("email")
	if len(email) == 0 {
		errs["email"] = "Ahem. You forgot your e-mail address."
	}

	pass := g.FormValue("password")
	repeatPass := g.FormValue("repeat-password")

	if len(pass) == 0 {
		errs["password"] = "You're gonna need a password."
	}

	if pass != repeatPass {
		errs["repeat-password"] = "If YOU don't know your own password, how am I supposed to know?"
	}

	if len(errs) > 0 {
		g.WriteHeader(400)
		g.JSON(map[string]interface{}{"ok": false, "errs": errs})
		return
	}

	hash, salt, err := gas.NewHash([]byte(pass))
	if err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	id := 0

	err = gas.DB.QueryRow(`
		INSERT INTO books.users
		( name, email, pass, salt )
		VALUES
		( $1, $2, $3, $4 )
		RETURNING id
		`, name, email, hash, salt).Scan(&id)

	if err != nil {
		g.WriteHeader(500)
		g.JSON(&AJAXResponse{false, err.Error()})
		return
	}

	sendActivationEmail(id, name, email)

	g.Render("books", "signup-almostdone", nil)
}
