﻿// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System.Runtime.CompilerServices;
using PChecker.SystematicTesting;

namespace PChecker.Random
{
    /// <summary>
    /// Represents a pseudo-random value generator, which is an algorithm that produces
    /// a sequence of values that meet certain statistical requirements for randomness.
    /// During systematic testing, the generation of random values is controlled, which
    /// allows the runtime to explore combinations of choices to find bugs.
    /// </summary>
    public class Generator
    {
        /// <summary>
        /// The runtime associated with this random value generator.
        /// </summary>
        internal readonly ControlledRuntime Runtime;

        /// <summary>
        /// Initializes a new instance of the <see cref="Generator"/> class.
        /// </summary>
        private Generator()
        {
            Runtime = ControlledRuntime.Current;
        }

        /// <summary>
        /// Creates a new pseudo-random value generator.
        /// </summary>
        /// <returns>The pseudo-random value generator.</returns>
        public static Generator Create() => new Generator();

        /// <summary>
        /// Returns a random boolean, that can be controlled during testing.
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public bool NextBoolean() => Runtime.GetNondeterministicBooleanChoice(2, null, null);

        /// <summary>
        /// Returns a random boolean, that can be controlled during testing.
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public bool NextBoolean(int maxValue) => Runtime.GetNondeterministicBooleanChoice(maxValue, null, null);

        /// <summary>
        /// Returns a random integer, that can be controlled during testing.
        /// </summary>
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public int NextInteger(int maxValue) => Runtime.GetNondeterministicIntegerChoice(maxValue, null, null);
    }
}