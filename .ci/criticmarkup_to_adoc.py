import re
import sys
import textwrap

DELETION_REGEXP = re.compile(r'\{--(.*?)--\}', re.DOTALL)
ADDITION_REGEXP = re.compile(r'\{\+\+(.*?)\+\+\}', re.DOTALL)
SUBSTITUTION_REGEXP = re.compile(r'\{~~(.*?)~>(.*?)~~\}', re.DOTALL)


class Deletor:

    def __init__(self, changes, note_fmt, replacement_fmt):
        self.n_deletions = 0
        self.changes = changes
        self.note_fmt = note_fmt
        self.replacement_fmt = replacement_fmt

    def __call__(self, match):
        self.n_deletions += 1

        def callback(n_deletions, match):
            m = match.group(1).replace('\n', ' ')
            txt = self.replacement_fmt.replace('{PREVIOUS}', m)
            note = self.note_fmt.replace('{PREVIOUS}', m)
            change_id = f'deletion-{n_deletions}'
            self.changes.append(change_id)
            return f'[[{change_id}, {note}]]\n{txt}'

        return callback(self.n_deletions, match)


class Additor:

    def __init__(self, changes, note_fmt, replacement_fmt):
        self.n_additions = 0
        self.changes = changes
        self.note_fmt = note_fmt
        self.replacement_fmt = replacement_fmt

    def __call__(self, match):
        self.n_additions += 1

        def callback(n_additions, match):
            m = match.group(1).replace('\n', ' ')
            txt = self.replacement_fmt.replace('{CURRENT}', m)
            note = self.note_fmt.replace('{CURRENT}', m)
            change_id = f'addition-{n_additions}'
            self.changes.append(change_id)
            return f'[[{change_id}, {note}]]\n{txt}'

        return callback(self.n_additions, match)


class Substituter:

    def __init__(self, changes, note_fmt, replacement_fmt,
                 wrap_long_strings_at=None):
        self.n_substitutions = 0
        self.changes = changes
        self.note_fmt = note_fmt
        self.replacement_fmt = replacement_fmt
        self.wrap_long_strings_at = wrap_long_strings_at

    def shorten(self, string):
        if self.wrap_long_strings_at is not None:
            return textwrap.shorten(string,
                                    self.wrap_long_strings_at,
                                    placeholder='...')
        return string

    def __call__(self, match):
        self.n_substitutions += 1

        def callback(n_substitutions, match):
            previous = match.group(1).replace('\n', ' ')
            current = match.group(2).replace('\n', ' ')

            short_previous = self.shorten(previous)
            short_current = self.shorten(current)

            txt = self.replacement_fmt.replace('{CURRENT}', current) \
                                      .replace('{PREVIOUS}', previous)
            note = self.note_fmt.replace('{CURRENT}', short_current) \
                                .replace('{PREVIOUS}', short_previous)

            change_id = f'substitution-{n_substitutions}'
            self.changes.append(change_id)
            return f'[[{change_id}, {note}]]\n{txt}'

        return callback(self.n_substitutions, match)


class CriticMarkupPreprocessor:

    def __init__(self,
                 change_listing_fmt='- {CHANGE}',
                 addition_note_fmt='Added "{CURRENT}"',
                 addition_replacement_fmt='{CURRENT}',
                 deletion_note_fmt='Deleted "{PREVIOUS}"',
                 deletion_replacement_fmt='(used to be "{PREVIOUS}")',
                 substitution_note_fmt='Changed "{PREVIOUS}" to "{CURRENT}"',
                 substitution_replacement_fmt='{CURRENT} (used to be "{PREVIOUS}")'): # noqa
        self.changes = []
        self.change_listing_fmt = change_listing_fmt
        self.addition_note_fmt = addition_note_fmt
        self.addition_replacement_fmt = addition_replacement_fmt
        self.deletion_note_fmt = deletion_note_fmt
        self.deletion_replacement_fmt = deletion_replacement_fmt
        self.substitution_note_fmt = substitution_note_fmt
        self.substitution_replacement_fmt = substitution_replacement_fmt

    def convert(self, infile):
        d = Deletor(self.changes,
                    self.deletion_note_fmt,
                    self.deletion_replacement_fmt)
        a = Additor(self.changes,
                    self.addition_note_fmt,
                    self.addition_replacement_fmt)
        s = Substituter(self.changes,
                        self.substitution_note_fmt,
                        self.substitution_replacement_fmt)

        with open(infile) as f:
            instr = f.read()
            instr = DELETION_REGEXP.sub(d, instr)
            instr = ADDITION_REGEXP.sub(a, instr)
            instr = SUBSTITUTION_REGEXP.sub(s, instr)

        list_of_changes = [self.change_listing_fmt.replace('{CHANGE}',
                                                           change)
                           for change in self.changes]
        changes = '\n'.join(list_of_changes)

        instr = instr.replace('{+-~TOC-CHANGES~-+}', changes)
        return instr


if __name__ == '__main__':
    cmp = CriticMarkupPreprocessor(
        change_listing_fmt='- <<{CHANGE}>>',
        addition_note_fmt='Added "{CURRENT}"',
        addition_replacement_fmt='[red]#*{CURRENT}*#',
        deletion_note_fmt='Deleted "{PREVIOUS}"',
        deletion_replacement_fmt='footnote:[In previous version this said "{PREVIOUS}"]', # noqa
        substitution_note_fmt='Changed "{PREVIOUS}" to "{CURRENT}"',
        substitution_replacement_fmt='[red]#*{CURRENT}*#\nfootnote:[In previous version this said "{PREVIOUS}"]' # noqa
    )
    print(cmp.convert(sys.argv[1]))
