---
layout: default
built_from_commit: f7b1a950d990274b9f352eb7aa0cd93ee6067df1
title: 'Resource Type: stage'
canonical: "/puppet/latest/types/stage.html"
---

# Resource Type: stage

> **NOTE:** This page was generated from the OpenVox source code on 2026-07-14 18:42:41 +0000



## stage

* [Attributes](#stage-attributes)

### Description {#stage-description}

A resource type for creating new run stages.  Once a stage is available,
classes can be assigned to it by declaring them with the resource-like syntax
and using
[the `stage` metaparameter](https://docs.openvoxproject.org/openvox/latest/metaparameter.html#stage).

Note that new stages are not useful unless you also declare their order
in relation to the default `main` stage.

A complete run stage example:

    stage { 'pre':
      before => Stage['main'],
    }

    class { 'apt-updates':
      stage => 'pre',
    }

Individual resources cannot be assigned to run stages; you can only set stages
for classes.

### Attributes {#stage-attributes}

<pre><code>stage { 'resource title':
  <a href="#stage-attribute-name">name</a> =&gt; <em># <strong>(namevar)</strong> The name of the stage. Use this as the value for </em>
  # ...plus any applicable <a href="https://docs.openvoxproject.org/openvox/latest/metaparameter.html">metaparameters</a>.
}</code></pre>


#### name {#stage-attribute-name}

_(**Namevar:** If omitted, this attribute's value defaults to the resource's title.)_

The name of the stage. Use this as the value for the `stage` metaparameter
when assigning classes to this stage.

([↑ Back to stage attributes](#stage-attributes))





