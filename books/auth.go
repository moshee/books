package books

import (
	"errors"
	"github.com/moshee/gas"
	"time"
)

type DBStore struct{}

// collapse the common exec error handling code into here
func exec(query string, args ...interface{}) error {
	res, err := gas.DB.Exec(query, args...)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return errors.New("books: session: no rows affected")
	}
	return nil
}

func (DBStore) CreateSession(name, id []byte, expires time.Time, username string) error {
	return exec(`INSERT INTO books.sessions VALUES
		( $1, (SELECT id FROM books.users WHERE name = $2 OR email = $2), $3 )`, id, username, expires)
}

func (DBStore) ReadSession(name, id []byte) (*gas.Session, error) {
	var (
		expires  time.Time
		username string
	)

	gas.Log(gas.Debug, "Sessname: %x", name)
	gas.Log(gas.Debug, "Sessid: %x", id)

	row := gas.DB.QueryRow("SELECT * FROM books.user_sessions WHERE id = $1", name)
	err := row.Scan(&id, &expires, &username)
	if err != nil {
		gas.Log(gas.Debug, "read session: %v", err)
		return nil, err
	}

	return &gas.Session{string(name), id, []byte{}, expires, username}, nil
}

func (DBStore) UpdateSession(name, id []byte) error {
	sess, err := DBStore{}.ReadSession(id, name)
	if err != nil {
		return err
	}
	return exec("UPDATE books.sessions SET expires = $1 WHERE id = $2",
		time.Now().Add(gas.MaxCookieAge), sess.Sessid)
}

func (DBStore) DeleteSession(name, id []byte) error {
	return exec("DELETE FROM books.sessions WHERE id = $1", name)
}

func (DBStore) UserAuthData(username string) (pass, salt []byte, err error) {
	row := gas.DB.QueryRow("SELECT pass, salt FROM books.users WHERE name = $1 OR email = $1", username)
	err = row.Scan(&pass, &salt)
	return
}

func (DBStore) User(username string) (gas.User, error) {
	user := new(User)
	err := gas.QueryRow(user, "SELECT * FROM books.users WHERE name = $1 OR email = $1", username)
	if err != nil {
		// instead of returning nil, return an interface containing nil. This
		// will allow us to always do a type assertion, which can yield a nil
		// concrete type. Useful for condensing logic dealing with passing a
		// user into a template, etc.
		return gas.User((*User)(nil)), err
	}
	return user, nil
}

func (DBStore) NilUser() gas.User {
	return gas.User((*User)(nil))
}
