#!/usr/bin/perl

## O.Salaün (23/07/2015) : script to move IMAP folders to another IMAP server

## TODO : see migrate() method, cf http://search.cpan.org/~djkernen/Mail-IMAPClient-2.2.9/IMAPClient.pod

## Examples :
##   ./imap_copy.pl --config=Conf.pm --list_folders --src_server=imap_src
##   ./imap_copy.pl --config=Conf.pm --list_messages --src_server=imap_src --src_folder=INBOX
##   ./imap_copy.pl --config=Conf.pm --migrate --src_server=imap_src --src_folder=Perso --dest_server=imap_dest --dest_folder=_Test
##   ./imap_copy.pl --config=Conf.pm --migrate --src_server=imap_src  --dest_server=imap_dest
##   ./imap_copy.pl --config=Conf.pm --rename_folder --src_server=imap_src --src_folder=Archives --dest_folder=_Archives

use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path($0));

use ImapCopy::Imap;
use ImapCopy::Tools;
use Data::Dumper;
use Getopt::Long;


my %options;
&GetOptions(\%options, 'help', 'config=s','delete_folder','delete_message','dest_folder=s','dest_server=s','expunge','flags','id=s','list_folders','list_messages','migrate','rename_folder','src_server=s','src_folder=s','headers=s');

if ($options{'help'}) {
    printf "./imap_copy.pl --config=Conf.pm --list_folders --src_server=imap_src\n";
    printf "./imap_copy.pl --config=Conf.pm --list_messages --src_server=imap_src --src_folder=INBOX\n";
    printf "./imap_copy.pl --config=Conf.pm --list_messages --src_server=imap_src --src_folder=INBOX --headers='From,Date,X-Renater-SpamState,X-Renater-SpamScore,X-Spam-Status'\n";
    printf "./imap_copy.pl --config=Conf.pm --expunge --src_server=imap_src --src_folder=INBOX\n";
    printf "./imap_copy.pl --config=Conf.pm --delete_message --id=xxx --src_server=imap_src --src_folder=Inbox\n";
    printf "./imap_copy.pl --config=Conf.pm --flags --id=xxx --src_server=imap_src --src_folder=Inbox\n";
    printf "./imap_copy.pl --config=Conf.pm --migrate --src_server=imap_src --src_folder=Perso --dest_server=imap_dest --dest_folder=_Test\n";
    printf "./imap_copy.pl --config=Conf.pm --migrate --src_server=imap_src  --dest_server=imap_dest\n";
    printf "./imap_copy.pl --config=Conf.pm --rename_folder --src_server=imap_src --src_folder=Archives --dest_folder=_Archives\n";
    exit 0;
}

unless ($options{'config'} and -f $options{'config'}) {
    die "Missing --config option";
}

unless (require $options{'config'}) {
    die "Fail to load configuration from $options{'config'}";
}


## Connect to IMAP servers
my %imap_servers;
foreach my $server_name (keys %imap_config) {
    my $server_config = $imap_config{$server_name};
    printf "Connect to IMAP server %s\n", $server_config->{'server'};
    $imap_servers{$server_name} = new ImapCopy::Imap(%{$server_config});
    
    unless (defined $imap_servers{$server_name}) {
	die "Failed to connect to IMAP server '".$server_config->{'server'}."'";
    }
	
    unless (defined $imap_servers{$server_name}->connect()) {
	die "Failed to connect to IMAP server '".$server_config->{'server'}."'";
    } 
}
    
my ($src_imap, $dest_imap);
if ($options{'src_server'}) {
    
    unless (defined $imap_servers{$options{'src_server'}}) {
	die "Undefined server '%s'", $options{'src_server'};
    }
    
    $src_imap = $imap_servers{$options{'src_server'}};
}

if ($options{'dest_server'}) {

    unless (defined $imap_servers{$options{'dest_server'}}) {
	die "Undefined server '%s'", $options{'sdestserver'};
    }
    
    $dest_imap = $imap_servers{$options{'dest_server'}};
}

if ($options{'list_folders'}) {
    unless (defined $src_imap) {
	die "First set 'select_src';"
    }
    
    printf "List folders from %s\n", $src_imap->{'server'};
    ## List folders
    my @folders;
    unless (@folders = $src_imap->list_folders()) {
	do_log('error', "Failed to list folders on IMAP server '%s'", $src_imap->{'server'});
	exit -1;
    }
    
    printf Data::Dumper::Dumper(\@folders);

}elsif ($options{'list_messages'}) {
    unless ($options{'src_folder'}) {
	die "Missing 'src_folder' option";
    }
    
    unless (defined $src_imap) {
	die "First set 'select_src';"
    }

    printf "Search messages\n";
    ## List messages in Folder
    my @messages;
    my @headers = split(',', $options{'headers'});
    unless (%messages = $src_imap->search_messages_in_folder($options{'src_folder'}, \@headers)) {
        do_log('error', "Failed to search on IMAP server '%s'", $src_imap->{'server'});
        exit -1;
    }
    
    printf Data::Dumper::Dumper(\%messages);
    
}elsif ($options{'expunge'}) {
    unless ($options{'src_folder'}) {
	die "Missing 'src_folder' option";
    }
    
    unless (defined $src_imap) {
	die "First set 'select_src';"
    }

    printf "Search messages\n";
    ## List messages in Folder
    my @messages;
    unless ($src_imap->expunge($options{'src_folder'})) {
	do_log('error', "Failed to expunge folder '%s' on IMAP server '%s'", $options{'src_folder'}, $src_imap->{'server'});
	exit -1;
    }
    
    printf "Done expunge on folder '%s'\n", $options{'src_folder'};
    
}elsif ($options{'delete_message'}) {
    unless ($options{'id'}) {
        die "Missing 'id' option";
    }
    
    unless ($options{'src_folder'}) {
        die "Missing 'src_folder' option";
    }
    
    unless (defined $src_imap) {
        die "First set 'select_src';"
    }
      
    unless ($src_imap->delete_message($options{'src_folder'}, $options{'id'})) {
        do_log('error', "Failed to delete message '%s' on IMAP server '%s'", $options{'id'}, $src_imap->{'server'});
        exit -1;
    }
    
    printf "Message %s deleted\n", $options{'id'};
  
}elsif ($options{'flags'}) {
    unless ($options{'id'}) {
        die "Missing 'id' option";
    }
    
    unless ($options{'src_folder'}) {
        die "Missing 'src_folder' option";
    }
    
    unless (defined $src_imap) {
        die "First set 'select_src';"
    }
      
    unless (my $flags = $src_imap->flags($options{'src_folder'}, $options{'id'})) {
        do_log('error', "Failed to get message flags for '%s' on IMAP server '%s'", $options{'id'}, $src_imap->{'server'});
        exit -1;
    }
    
    printf Data::Dumper::Dumper($flags);
  
}elsif ($options{'migrate'}) {
    
    unless (defined $src_imap) {
	die "First set 'src_server';"
    }

    unless (defined $dest_imap) {
	die "First set 'dest_server';"
    }

    our %migrate_folder;
    if ($options{'src_folder'} && $options{'dest_folder'}) {
	%migrate_folder = ($options{'src_folder'} => $options{'dest_folder'});
    }else {
	## Using mapping defined in configuration file
	unless (%migrate_map) {
	    die "You should either define --src_folder and --dest_folder of define %migrate_map in your configuration file for batch migration";
	}
    }

    foreach my $src_folder (keys %migrate_map) {
	my $dest_folder = $migrate_map{$src_folder};
	printf "Migrate content of server %s, folder %s TO server %s, folder %s\n", $src_imap->{'server'}, $src_folder, $dest_imap->{'server'}, $dest_folder;
	
	my $result = $src_imap->migrate_folder(src_folder => $src_folder,
						dest_server => $dest_imap,
						dest_folder => $dest_folder);
	unless (defined $result ) {
	    die "Failed to migrate messages";
	}
	
	printf "Done migrating %d messages\n", $result;
    }

}elsif ($options{'delete_folder'}) {
    unless ($options{'src_folder'}) {
	die "Missing 'src_folder' option";
    }
    
    unless (defined $src_imap) {
	die "First set 'select_src';"
    }

    printf "Deleting folder $options{'src_folder'} on server %s\n", $src_imap->{'server'};
    printf "Confirm (y/n):";
    my $confirmation = <STDIN>; chomp $confirmation;
    
    unless ($confirmation eq "y") {
	die "Canceled";
    }
    
    unless ($src_imap->delete_folder($options{'src_folder'})) {
	die "Failed to delete folder";
    }
    
    printf "Done\n";
}elsif ($options{'rename_folder'}) {
    unless ($options{'src_folder'}) {
	die "Missing 'src_folder' option";
    }
    
    unless (defined $src_imap) {
	die "First set 'src_server';"
    }

    unless ($options{'dest_folder'}) {
	die "Missing 'dest_folder' option";
    }
        
    
    my $result = $src_imap->rename_folder(src_folder => $options{'src_folder'},
					    dest_folder => $options{'dest_folder'});
    unless (defined $result ) {
	die "Failed to migrate messages";
    }
    
    printf "Done renaming folder %s to %s\n", $options{'src_folder'}, $options{'dest_folder'};    
}

## Disconnect from IMAP servers
foreach my $server (values %imap_servers) {
    $server->disconnect();
}
