# Contributing Guidelines

We welcome contributions to this aircraft, but please have a look at the following guidelines, to ensure similarity and proper maintain-ability throughout the project.

## Basic Guidelines:
- Use Tabs to indent code, DO NOT USE SPACE.
- Use lowerCamelCase or underscores for naming Nasal variables/functions (someFunction, some_function).
- Comments optional for XML, mandatory for Nasal.
- Do not add a comment to every line, only to functions/groups of code.
- Remove .bak or .blend files, unless absolutely needed.
- Leave one extra line at the bottom of each file.

## Formatting Guidelines:
Indenting and Line Breaks:
```
<!-- XML -->
<something>
	<something-else>0</something-else>
	<something-more>
		<more-stuff></more-stuff>
	</something-more>
</something>
```

```
# Nasal
var something = func {
	somethingElse();
}
```
Brackets, Spaces, Commas, Semi-Colons, and Parentheses:
```
var something = 0;
var someOtherThing = func {
	if (something == 1) {
		something = 0;
	} else {
		something = 1;
	}
	settimer(func {
		setprop("/something", something);
	}, 5);
}
```
