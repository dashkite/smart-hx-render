import { generic } from "@dashkite/joy/generic"
import * as It from "@dashkite/joy/iterable"
import * as T from "@dashkite/joy/type"
import * as Val from "@dashkite/joy/value"
import Registry from "@dashkite/helium"

isAny = (x) -> true

entries = (object) -> Object.entries object

attribute = (r, [key, value]) -> r += "#{key}='#{value}'"

attributes = (object) ->
  It.reduce attribute, "", entries object

tag = generic name: "tag"

generic tag, T.isString, (name) -> "<#{name}/>"

generic tag, T.isString, T.isObject, (name, ax) ->
  "<#{name} #{attributes ax}/>"

generic tag, T.isString, T.isString, (name, content) ->
  "<#{name}>#{content}</#{name}>"

generic tag, T.isString, T.isObject, T.isString, (name, ax, content) ->
  "<#{name} #{attributes ax}>#{content}</#{name}>"

generic tag, T.isString, T.isArray, (name, content) ->
  tag name, It.join "", It.select T.isDefined, content

generic tag, T.isString, T.isObject, T.isArray, (name, ax, content) ->
  tag name, ax, It.join "", It.select T.isDefined, content

generic tag, T.isString, Val.isEmpty, (name) -> tag.name
generic tag, T.isString, T.isUndefined, (name) -> tag name
generic tag, T.isString, Val.isEmpty, isAny, (name, ignore, value) -> tag name, value
generic tag, T.isString, T.isUndefined, isAny, (name, ignore, value) -> tag name, value
generic tag, T.isString, isAny, Val.isEmpty, (name, value) -> tag name, value
generic tag, T.isString, isAny, T.isUndefined, (name, value) -> tag name, value

router = undefined

project = (data, properties) ->
  r = {}
  if properties?
    for key, value of properties
      r[key] = data[value]
  r

prefix = (prefix, properties) ->
  r = {}
  if properties?
    for key, value of properties
      r["#{prefix}-#{key}"] = value
  r

fields = ({ form, data }) ->
  router ?= await Registry.get "router"
  if form.groups?
    for group in form.groups
      tag "section", await fields { form: group, data }
  else
    for field in form.fields
      tag "section", do ->
        switch field.element
          when "text input"
            tag (field.label.element ? "label"), [
              tag "div", class: "label", field.label.text
              if field.disabled
                tag "input", type: "text", disabled: true, value: data[field.value]
              else
                tag "input", type: "text", value: data[field.value]
              if field.hint?
                tag "div", class: "hint", field.hint
            ]
          when "link"
            [
              tag "a",
                href: (router.link 
                  name: field.reference.name, 
                  parameters: project data, field.reference.parameters)
                field.text 
            ]
          else
            [
              tag (field.label.element ? "label"), field.label.text
              tag (field.element ? "div"), (prefix "data", (project data, field.data)), data[field.value]
            ]

actions = ({ form, data }) ->
  tag "footer",
    tag "nav", do ->
      for action in form.actions
        if action.default
          tag "button", class: "default", name: action.name, action.label
        else
          tag "button", name: action.name, action.label

html = ({form, data}) ->
  tag (form.element ? "article"), [
    (await fields { form, data })...
    if form.actions?
      actions { form, data }  
  ]
          

export default html
