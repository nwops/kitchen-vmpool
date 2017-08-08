require 'gitlab'


def client
  @client ||= Gitlab.client
end

def project_id
  @project_id ||= 630
end

def snippet_id
  @snippet_id ||= 89
end

def snippet_exists?(project = project_id)
  client.snippets(project, { title: 'Virtual Machine Pools', visibility: 'public', file_name: 'vmpool.yaml', code: File.read('vmpool.yaml')})
end

def create_snippet(project = project_id)
  client.create_snippet(project, { title: 'Virtual Machine Pools', visibility: 'public', file_name: 'vmpool.yaml', code: File.read('vmpool.yaml')})
end

def update_snippet(project = project_id, content = File.read('vmpool.yaml'))
  client.edit_snippet(project, snippet_id, { title: 'Virtual Machine Pools', visibility: 'public', file_name: 'vmpool.yaml', code: content})
end

def project_snippets(project = project_id)
  client.snippets(project).map {|s| s.id }
end

def read_snippet(project = project_id, id = snippet_id)
  client.snippet_content(project, id)
end

word = ARGV.first || 'read'
case word.downcase
when 'update'
  update_snippet
  puts "Reading snippet"
  puts read_snippet
when 'create'
  create_snippet
  puts "Reading snippet"
  puts read_snippet
else
  puts "Reading snippet"
  puts read_snippet
end
