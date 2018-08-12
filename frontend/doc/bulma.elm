{--
	hero:       https://bulma.io/documentation/layout/hero/
	section:    https://bulma.io/documentation/layout/section/
	image:      https://bulma.io/documentation/elements/image/
	columns:    https://bulma.io/documentation/columns/basics/
	media:      https://bulma.io/documentation/layout/media-object/
	icon:       https://bulma.io/documentation/elements/icon/
	breadcrumb: https://bulma.io/documentation/components/breadcrumb/
	level:      https://bulma.io/documentation/layout/level/
--}

-- hero: https://bulma.io/documentation/layout/hero/ -->
section [ class "hero" ]
    [
    div [class "hero-header"]
        [ -- content
        ]
    , div [class "hero-body"]
        [ -- content
        ]
    ]

-- section: https://bulma.io/documentation/layout/section/ -->
section [ class "section" ]
    [ div [class "container"]
          [ -- content
          ]
    ]

-- image: https://bulma.io/documentation/elements/image/ -->
figure [ class "image is-128x128" ]
    [ img [src "https://bulma.io/images/placeholders/128x128.png"]
          [ -- content
          ]
    ]

-- columns: https://bulma.io/documentation/columns/basics/ -->
<div class="columns">
    <div class="column">
        <!-- ... -->
    </div>
</div>

-- media: https://bulma.io/documentation/layout/media-object/ -->
<article class="media">
    <figure class="media-left">
        <!-- ... -->
    </figure>
    <div class="media-content">
        <div class="content">
            <!-- ... -->
        </div>
    </div>
</article>

-- icon: https://bulma.io/documentation/elements/icon/ -->
<span class="icon has-text-success">
	<i class="fas fa-check-square"></i>
</span>

-- breadcrumb: https://bulma.io/documentation/components/breadcrumb/ -->
<nav class="breadcrumb" aria-label="breadcrumbs">
    <ul>
        <li><a href="#"><!-- ... --></a></li>
        <li class="is-active"><a href="#" aria-current="page"><!-- ... --></a></li>
    </ul>
</nav>

-- level: https://bulma.io/documentation/layout/level/ -->
<div class="level">
    <div class="level-item">
        <!-- ... -->
    </div>
</div>