using JSON
using OrderedCollections

struct URL
    url::String
    scheme::String
    username::String
    password::String
    authenticate::String
    host::String
    subdomain::String
    domain::String
    tld::String
    port::String
    path::String
    directory::String
    file::String
    file_name::String
    file_extension::String
    query::String
    fragment::String
    parameters::Vector{String}
    parameters_count::Int32
    parameters_value::Vector{String}
    parameters_value_count::Int32

    _scheme::String
    _auth::String
    _host::String
    _port::String
    _path::String
    _query::String
    _fragment::String
end

function Decode(st::AbstractString)
    decode = Dict{Regex,String}(
        r"%20"i => " ",
        r"%21"i => "!",
        r"%22"i => "\"",
        r"%23"i => "#",
        r"%24"i => "\$",
        r"%25"i => "%",
        r"%26"i => "&",
        r"%27"i => "'",
        r"%28"i => "(",
        r"%29"i => ")",
        r"%2a"i => "*",
        r"%2b"i => "+",
        r"%2c"i => ",",
        r"%2d"i => "-",
        r"%2e"i => ".",
        r"%2f"i => "/",
        r"%30"i => "0",
        r"%31"i => "1",
        r"%32"i => "2",
        r"%33"i => "3",
        r"%34"i => "4",
        r"%35"i => "5",
        r"%36"i => "6",
        r"%37"i => "7",
        r"%38"i => "8",
        r"%39"i => "9",
        r"%40"i => "@",
        r"%60"i => "`",
        r"%2a"i => "*",
        r"%2b"i => "+",
        r"%2c"i => ",",
        r"%2d"i => "-",
        r"%2e"i => ".",
        r"%2f"i => "/",
        r"%3a"i => ":",
        r"%3b"i => ";",
        r"%3c"i => "<",
        r"%3d"i => "=",
        r"%3e"i => ">",
        r"%3f"i => "?",
        r"%5b"i => "[",
        r"%5c"i => "\\",
        r"%5d"i => "]",
        r"%5e"i => "^",
        r"%5f"i => "_",
        r"%7b"i => "{",
        r"%7c"i => "|",
        r"%7d"i => "}",
        r"%7e"i => "~",
        r"%7f"i => "",
        r"%0c"i => "",
        r"&quot;" => "\"",
        r"amp;" => "",
        r"&lt;" => "<",
        r"&gt;" => ">",
        r"&#39;" => "'"
    )
    return replace(replace(st, decode...), "&&" => "&")
end

function check_str(input::Union{AbstractString,Nothing})
    !isnothing(input) ? input : ""
end

function extract(host::String)
    tlds = Set()
    for line in eachline("src/tlds.txt")
        occursin(Regex("\\b$line\\b\\Z"), host) && push!(tlds, line)
    end
    tld = argmax(length, tlds)
    rest = rsplit(replace(host, tld => ""), ".", limit=2)
    if length(rest) > 1
        subdomain, domain = rest
    else
        subdomain = ""
        domain = rest[1]
    end
    return (subdomain, domain, strip(tld, '.'))
end

function file_apart(file::String)
    file_name::String, file_extension::String = occursin(".", file) ? split(file, ".", limit=2, keepempty=true) : split(file * ".", ".", limit=2, keepempty=true)
    return file_name, file_extension
end

function _parameters(query::AbstractString)
    res = String[]
    reg = r"[\?\&\;]([\w\-\~\+\%]+)"
    for param in eachmatch(reg, query)
        append!(res, param.captures)
    end
    return unique(res)
end

function _subs(url::URL)
    subdomain::String = url.subdomain
    unique(vcat([subdomain], split(subdomain, r"[\.\-]"), split(subdomain, ".")))
end

function _parameters_value(query::AbstractString; count::Bool=false)
    res = String[]
    reg = r"\=([\w\-\%\.\:\~\,\"\'\<\>\=\(\)\`\{\}\$\+\/\;\#]*)?"
    for param in eachmatch(reg, query)
        append!(res, param.captures)
    end
    if count
        return length(res)
    end
    return unique(filter(!isempty, res))
end

function Json(url::URL)
    parts = OrderedDict{String,Any}(
        "url" => url.url,
        "scheme" => url.scheme,
        "username" => url.username,
        "password" => url.password,
        "authenticate" => url.authenticate,
        "host" => url.host,
        "subdomain" => url.subdomain,
        "subdomain_combination" => _subs(url),
        "domain" => url.domain,
        "tld" => url.tld,
        "port" => url.port,
        "path" => url.path,
        "directory" => url.directory,
        "file" => url.file,
        "file_name" => url.file_name,
        "file_ext" => url.file_extension,
        "query" => chopprefix(url.query, "?"),
        "fragment" => url.fragment,
        "parameters" => url.parameters,
        "parameters_count" => url.parameters_count,
        "parameters_value" => url.parameters_value,
        "parameters_value_count" => url.parameters_value_count,
    )
    JSON.print(parts, 4)
end

function SHOW(url::URL)
    items = """
    * url:            $(url.url)
    * scheme:         $(url.scheme)
    * username:       $(url.username)
    * password:       $(url.password)
    * authenticate:   $(url.authenticate)
    * host:           $(url.host)
    * subdomain:      $(url.subdomain)
    * domain:         $(url.domain)
    * tld:            $(url.tld)
    * port:           $(url.port)
    * path:           $(url.path)
    * directory:      $(url.directory)
    * file:           $(url.file)
    * file_name:      $(url.file_name)
    * file_extension: $(url.file_extension)
    * query:          $(url.query)
    * fragment:       $(url.fragment)
    * subdomain_comb: $(join(_subs(url), " "))
    * parameters:     $(join(url.parameters, " "))
    * params count:   $(url.parameters_count)
    * values:         $(join(url.parameters_value, " "))
    * values count:   $(url.parameters_value_count)
    """
    println(items)
end


function URL(Url::AbstractString)
    url::String = Decode(Url)
    url = chopprefix(url, "*.")
    parts = match(r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?(?<port>(\d+))?(?<path>([\/\w\-\.\%\,\"\'\<\>\=\(\)]+))?(?<query>\?(.*?))?(?<fragment>\#([^\#]*?))?$", url)

    Url::String = url
    scheme::String = check_str(parts["scheme"])
    username::String = check_str(parts["username"])
    password::String = check_str(parts["password"])
    authenticate::String = chopsuffix(check_str(parts[4]), "@")
    host::String = chopprefix(check_str(parts["host"]), "www.")
    subdomain::String, domain::String, tld::String = extract(host)
    port::String = check_str(parts["port"])
    path::String = check_str(parts["path"])
    directory::String = dirname(path)
    file::String = basename(path)
    file_name::String, file_extension::String = file_apart(file)
    query::String = check_str(parts["query"])
    fragment::String = chopprefix(check_str(parts["fragment"]), "#")
    parameters::Vector{String} = _parameters(query)
    parameters_count::Int32 = length(parameters)
    parameters_value::Vector{String} = _parameters_value(query)
    parameters_value_count::Int32 = _parameters_value(query, count=true)

    _scheme::String = check_str(parts[1])
    _auth::String = _scheme * check_str(parts[4])
    _host::String = match(r"^((?<scheme>([a-zA-Z]+)):\/\/)?((?<username>([\w\-]+))\:?(?<password>(.*?))\@)?(?<host>([\w\-\.]+)):?", url).match
    _port::String = _host * port
    _path::String = _port * path
    _query::String = _path * query
    _fragment::String = url

    return URL(Url, scheme, username, password, authenticate, host, subdomain, domain, tld, port, path, directory, file, file_name, file_extension, query, fragment, parameters, parameters_count, parameters_value, parameters_value_count, _scheme, _auth, _host, _port, _path, _query, _fragment)
end