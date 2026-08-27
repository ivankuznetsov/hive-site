# frozen_string_literal: true

# AI-native docs generator.
#
# After Jekyll writes the site, this emits:
#   * each docs page as clean raw markdown at a stable `<page>.md` URL
#   * /llms.txt       — curated index (llmstxt.org convention)
#   * /llms-full.txt  — every docs page concatenated into one corpus
#
# Everything is derived from the published docs pages, so it tracks exactly the
# curated/public set — internal wiki pages are never sources here, and so never
# leak (R4). Cloudflare `_headers` serves these as text/markdown with CORS, so
# an agent can fetch and read them directly.

require "fileutils"

module HiveLlm
  BASE = "https://hivecli.sh"

  module_function

  # Real, public docs content pages (not the generated .md, not nav-excluded).
  def docs_pages(site)
    site.pages.select do |p|
      path = p.path.to_s
      path.start_with?("docs/") &&
        path.end_with?(".md") &&
        p.data["title"] &&
        p.data["nav_exclude"] != true
    end
  end

  # /docs/concepts/  -> /docs/concepts.md ; /docs/ -> /docs.md
  def md_path(page)
    "#{page.url.chomp('/')}.md"
  end

  def index_page?(page)
    File.basename(page.path.to_s) == "index.md"
  end

  # Strip front matter and resolve the small set of Liquid/kramdown constructs we
  # actually use, leaving clean, agent-readable markdown.
  def clean_markdown(raw, site)
    body = raw.sub(/\A---\s*\n.*?\n---\s*\n/m, "")
    body = body.gsub(/\{\{\s*'([^']+)'\s*\|\s*relative_url\s*\}\}/) { "#{BASE}#{Regexp.last_match(1)}" }
    body = body.gsub(/\{\{\s*site\.hive_version\s*\}\}/, site.config["hive_version"].to_s)
    body = body.gsub(/^\{:\s*\.no_toc\s*\}\s*$/, "")              # kramdown attr list
    body = body.gsub(/^1\.\s*TOC\s*$/, "").gsub(/^\{:toc\}\s*$/, "") # kramdown TOC scaffold
    "#{body.strip}\n"
  end

  def raw_source(site, page)
    # Cloudflare's build image defaults to US-ASCII; force UTF-8 so the docs'
    # em dashes / arrows / checkmarks don't blow up the regex below.
    File.read(site.in_source_dir(page.path), encoding: "UTF-8")
  end

  def sorted(pages)
    pages.sort_by { |p| [(p.data["nav_order"] || 99).to_i, p.data["title"].to_s] }
  end

  def section_pages(pages)
    sorted(pages.reject { |p| p.path.to_s.include?("commands/") || index_page?(p) })
  end

  def command_pages(pages)
    sorted(pages.select { |p| p.path.to_s.include?("commands/") && !index_page?(p) })
  end

  def link_line(page, prefix = "")
    desc = page.data["description"].to_s.strip
    "- [#{prefix}#{page.data['title']}](#{BASE}#{md_path(page)})#{desc.empty? ? '' : ": #{desc}"}"
  end

  def llms_txt(site, pages)
    out = +"# Hive\n\n"
    out << "> #{site.config['description'].to_s.strip}\n\n"
    out << "Hive is an open-source (MIT) command-line workflow engine that runs " \
           "reusable, multi-stage processes as durable task folders. Agents and " \
           "people leave reviewable artifacts at each handoff. Its flagship coding " \
           "workflow turns a rough idea into a merge-ready pull request; the same " \
           "engine also runs content, benchmark, and project-authored workflows. " \
           "Each page below is also available as raw markdown.\n\n"
    out << "## Docs\n\n"
    section_pages(pages).each { |p| out << "#{link_line(p)}\n" }
    out << "\n## Command reference\n\n"
    command_pages(pages).each { |p| out << "#{link_line(p, 'hive ')}\n" }
    out << "\n## Optional\n\n"
    out << "- [Full documentation in one file](#{BASE}/llms-full.txt): every page concatenated\n"
    out << "- [Source on GitHub](https://github.com/ivankuznetsov/hive)\n"
    out
  end

  def llms_full(site, pages)
    out = +"# Hive — full documentation\n\n"
    out << "> #{site.config['description'].to_s.strip}\n\n"
    out << "Generated from #{BASE}. Each section below is one docs page.\n"
    (section_pages(pages) + command_pages(pages)).each do |p|
      out << "\n\n---\n\n"
      out << "<!-- source: #{BASE}#{p.url} -->\n\n"
      out << clean_markdown(raw_source(site, p), site)
    end
    out
  end

  def write(site, rel_path, content)
    dest = File.join(site.dest, rel_path.sub(%r{\A/}, ""))
    FileUtils.mkdir_p(File.dirname(dest))
    File.write(dest, content, encoding: "UTF-8")
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  pages = HiveLlm.docs_pages(site)
  next if pages.empty?

  pages.each do |page|
    md = HiveLlm.clean_markdown(HiveLlm.raw_source(site, page), site)
    HiveLlm.write(site, HiveLlm.md_path(page), md)
  end

  HiveLlm.write(site, "/llms.txt", HiveLlm.llms_txt(site, pages))
  HiveLlm.write(site, "/llms-full.txt", HiveLlm.llms_full(site, pages))

  Jekyll.logger.info "HiveLlm:", "wrote #{pages.size} raw .md pages + llms.txt + llms-full.txt"
end
