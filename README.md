# ImapCopy to move your IMAP folders between IMAP servers

I've created this tool while moving to another job to help me move IMAP folders to either my new professionnal mailbox or my personal mailbox.

`imap_copy.pl` will copy content of IMAP folders to a destination server.

## Prerequisites

* Perl interpreter
* Mail::IMAPClient CPAN module : `$ sudo apt install libmail-imapclient-perl`

## Configuration

Configuration file is specified via imap_copy.pl `--config` argument.

See sample-Conf.pm :
```
# IMAP servers config
our %imap_config = (
		   imap_cru => {
			use_ssl => 1,
			server => 'src.example.com',
			port => 993,
			user => 'userX',
			password => 'XXX',
		    },
		   imap_renater => {
			use_ssl => 1,
			server => 'dest1.example.com',
			port => 993,
			user => 'userY',
			password => 'XXX',
		   },
		   imap_gmail => {
			use_ssl => 1,
			server => 'dest2.example.com',
			port => 993,
			user => 'userZ',
			password => 'XXX',
		   },
		  );

# Define IMAP folder mapping
our %migrate_map = (
	'Pro/X' => 'X',
          'Perso/Y'=>'Y',
          'Perso/Z'=>'Z',

);
```

## Examples

```./imap_copy.pl --config=Conf.pm --list_folders --src_server=imap_src
./imap_copy.pl --config=Conf.pm --list_messages --src_server=imap_src --src_folder=INBOX
./imap_copy.pl --config=Conf.pm --migrate --src_server=imap_src --src_folder=Perso --dest_server=imap_dest --dest_folder=_Test
./imap_copy.pl --config=Conf.pm --migrate --src_server=imap_src  --dest_server=imap_dest
./imap_copy.pl --config=Conf.pm --rename_folder --src_server=imap_src --src_folder=Archives --dest_folder=_Archives
```