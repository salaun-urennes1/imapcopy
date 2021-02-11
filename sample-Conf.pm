## Configuration file for imap_copy.pl

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

1;
