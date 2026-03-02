# Books YAML Format

`data/books.yml` is a list of book entries. Each entry is a YAML mapping.

## Fields

| Field | Required | Description |
|---|---|---|
| `title` | yes | Book title |
| `subtitle` | no | Book subtitle |
| `edition` | no | Edition (e.g. `1st Edition`) |
| `author` | yes | Author name |
| `editor` | no | Editor name |
| `rating` | no | 1–5 integer star rating |
| `associates_link` | no | Amazon affiliate URL |
| `commentary` | no | Personal notes/review |
| `date_started` | no | ISO date reading began (`YYYY-MM-DD`) |
| `date_finished` | no | ISO date finished; leave blank if in progress |
| `format_read` | no | How it was read (e.g. `Audible`, `hardcover`, `Digital on O'Reilly App`) |
| `print_length` | no | Page count as `"N pages"` — used for progress calculations |
| `listening_length` | no | Audiobook duration as `"H hours and M minutes"` |

## Progress tracking (in-progress books)

Provide **one** of the following to track partial progress:

| Field | Format | Example |
|---|---|---|
| `pages_read` | `"N pages"` | `26 pages` |
| `percent_complete` | `"N%"` | `55%` |
| `time_left` | `"H hours and M minutes"` (requires `listening_length`) | `3 hours and 20 minutes` |

If none are provided and the book has no `date_finished`, pages read is treated as 0.

## Example entries

Completed audiobook:
```yaml
- title: Dopesick
  subtitle: Dealers, Doctors, and the Drug Company that Addicted America
  author: Beth Macy
  date_finished: 2026-01-25
  format_read: Audible
  print_length: 400 pages
  listening_length: 10 hours and 16 minutes
  rating: 5
  associates_link: https://amzn.to/3YTtJPa
```

In-progress physical book with explicit page count:
```yaml
- title: How to Be an Antiracist
  author: Ibram X. Kendi
  date_started: 2026-02-28
  format_read: hardcover
  print_length: 320 pages
  pages_read: 26 pages
  associates_link: https://amzn.to/4sf5BD1
```

In-progress ebook with percent:
```yaml
- title: AI Engineering
  subtitle: Building Applications with Foundation Models
  author: Chip Huyen
  date_started: 2026-02-01
  format_read: Audiobook on O'Reilly App
  print_length: 532 pages
  percent_complete: 55%
  associates_link: https://amzn.to/4qnQVjW
```

## Notes

- Entries are ordered oldest-to-newest in the file; the visualizer sorts by date independently.
- `data/books_goodreads.yml` is a secondary source merged at generation time; manual `data/books.yml` entries take precedence on title conflicts.
- Run `ruby index_me.rb` to regenerate `books_all.html` and `books_completed.html` and sync to S3.
