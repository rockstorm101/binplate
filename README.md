# BinPlate

(Bin)ary to Tem(plate).
```
                  config
                    |
                    v
  input        +----------+
  template --> | binplate | --> output
               +----------+
```

Given a template like:
```
Hello {{ .name }}, Welcome to {{ .site }}!
```

And a configuration file like:
```yaml
name: John
site: Paradise
```

`binplate` will output:
```
Hello Jonh, Welcome to Paradise!
```

### Features

 * **Plenty of configuration file formats**
   It uses ['fq'][1] to read from configuration files. Therefore, it
   supports all the [formats supported by 'fq'][2]. Which includes
   many binary and text formats.

 * **Piping and scripting**
   It can take input from 'stdin' and output to 'stdout'. Therefore
   its input/output can be piped to other programs/tools.

 * **Multiple configuration files**
   It can read configuration from several files and apply them in
   order of preference.

 * **Custom templates**
   Several options allow adapting `binplate` to different template
   placeholders formats.

[1]: https://github.com/wader/fq
[2]: https://github.com/wader/fq#supported-formats


### Dependencies

 * Bash
 * [fq][1] [^1]


### Usage

The above example is produced with:
```bash
echo 'Hello {{ .name }}, Welcome to {{ .site }}!' | ./binplate.sh /path/to/config.yml
```

Running `./binplate.sh --help`:
```
Usage: binplate [options] FILE [FILE...]

Read a template, fill in placeholders in accordance with the values
stored in configuration FILE and output the result. By default, the
template is read from stdin and output is sent to stdout. If more than
one FILE is given, configurations from the first FILE will be
preferred over the second one and so on.

By default, template placeholders are expected to be in the form
'{{ placeholder }}'.

It uses 'fq' to read from configuration FILE. Therefore, it supports
all the formats supported by 'fq'.

Options:
  -b, --blanks       Allow for missing values in configuration FILE
                     and replace them with blanks instead of failing
  -f, --fq-options OPTS
                     Options for the 'jq' command (e.g. '-d yaml')
  -h, --help         Print this help and exit
  -i, --input FILE   Input file (default: stdin)
  -l, --left-delimiter STR
                     String that delimits placeholders from the left
                     (default: '{{ ')
  -o, --output FILE  Output file (default: stdout)
  -r, --right-delimiter STR
                     String that delimits placeholders from the right
                     (default: ' }}')
  -v, --verbose      Print script debug info
```

### Testing

Test suite uses the [BATS][3] framework. Running from the project root:
```
bats -x --verbose-run test/
```

[3]: https://github.com/bats-core/bats-core

### Credits

Flow diagram drawn with [asciiflow][4].

[4]: https://asciiflow.com


### License

```
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
```

See full [license information][5].

[5]: ./LICENSE


[^1]: Available on Debian/Ubuntu systems with just `apt install fq`.
